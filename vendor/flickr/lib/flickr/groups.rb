# rFlickr: A Ruby based Flickr API implementation.
# Copyright (C) 2009, Alex Pardoe (digital:pardoe)
#
# Derrived from work by Trevor Schroeder, see here:
# http://rubyforge.org/projects/rflickr/.
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

require 'flickr/base'

class Flickr::Groups < Flickr::APIBase
	def pools() @pools ||= Flickr::Pools.new(@flickr,self) end

	# category can be a Category or nsid string
	def browse(category=nil)
		category=category.id if (category.class == Flickr::Category ||
			  category.class == Flickr::SubCategory )

		args = category ?  {'cat_id' => category } : {}
		res = @flickr.call_method('flickr.groups.browse',args)
		att = res.root.attributes
		cat=Flickr::Category.new(att['name'],att['path'],att['pathids'])
		res.elements['/category'].each_element('subcat') do |e|
			att = e.attributes
			cat.subcats << Flickr::SubCategory.new(att['name'],
				att['id'],att['count'].to_i)
		end
		res.elements['/category'].each_element('group') do |e|
			att = e.attributes
			nsid = att['nsid']

			g = @flickr.group_cache_lookup(nsid)
			g ||= Flickr::Group.new(@flickr,nsid)

			g.name = att['name']
			g.members = att['members'].to_i
			g.online = att['online'].to_i
			g.chatnsid = att['chatnsid']
			g.inchat = att['inchat'].to_i

			@flickr.group_cache_store(g)
			cat.groups << g
		end

		return cat
	end

	# group can be a Group or group nsid
	def getInfo(group)
		group = group.nsid if group.class == Flickr::Group
		g = @flickr.group_cache_lookup(group)
		return g if g && g.fully_fetched

		res = @flickr.call_method('flickr.groups.getInfo',
			'group_id' => group)
		group = res.elements['/group'].attributes['id']
		g ||= Flickr::Group.new(@flickr,nsid)
		g.name = res.elements['/group/name'].text
		g.description = res.elements['/group/description'].text
		g.members = res.elements['/group/members'].text.to_i
		g.privacy = res.elements['/group/privacy'].text.to_i
		g.fully_fetched = true

		@flickr.group_cache_store(g)
		return g
	end

	def search(text,per_page=nil,page=nil)
		args = { 'text' => text }
		args['per_page'] = per_page if per_page
		args['page'] = page if page
		res = @flickr.call_method('flickr.groups.search',args)
		att = res.root.attributes
		list = Flickr::GroupList.new(att['page'].to_i,att['pages'].to_i,
			att['perpage'].to_i,att['total'].to_i)
		res.elements['/groups'].each_element('group') do |e|
			att = e.attributes
			nsid = att['nsid']
			g = @flickr.group_cache_lookup(nsid) ||
			  Flickr::Group.new(@flickr,nsid)
			g.name = att['name']
			g.eighteenplus = att['eighteenplus'].to_i == 1

			@flickr.group_cache_store(g)
			list << g
		end
		return list
	end

end
