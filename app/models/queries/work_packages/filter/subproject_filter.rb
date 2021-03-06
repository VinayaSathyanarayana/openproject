#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

class Queries::WorkPackages::Filter::SubprojectFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    @allowed_values ||= begin
      visible_subproject_array.map { |id, name| [name, id.to_s] }
    end
  end

  def available_operators
    [::Queries::Operators::All,
     ::Queries::Operators::None,
     ::Queries::Operators::Equals]
  end

  def available?
    project &&
      !project.leaf? &&
      visible_subprojects.any?
  end

  def type
    :list
  end

  def human_name
    I18n.t('query_fields.subproject_id')
  end

  def self.key
    :subproject_id
  end

  def ar_object_filter?
    true
  end

  def value_objects
    value_ints = values.map(&:to_i)

    visible_subprojects.where(id: value_ints)
  end

  def where
    ids = [project.id]

    case operator
    when '='
      # include the selected subprojects
      ids += values.each(&:to_i)
    when '*'
      ids += visible_subproject_array.map(&:first)
    end

    "#{Project.table_name}.id IN (%s)" % ids.join(',')
  end

  private

  def visible_subproject_array
    visible_subprojects.pluck(:id, :name)
  end

  def visible_subprojects
    # This can be accessed even when `available?` is false
    @visible_subprojects ||= begin
      if project.nil?
        []
      else
        project.descendants.visible
      end
    end
  end

  def operator_strategy
    case operator
    when '*'
      ::Queries::Operators::All
    when '!*'
      ::Queries::Operators::None
    when '='
      ::Queries::Operators::Equals
    end
  end
end
