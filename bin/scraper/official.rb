#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

class MemberList
  class Member
    def name
      Name.new(
        full:     positionless_name,
        prefixes: ['Honourable']
      ).short
    end

    def position
      ([name_position] + [line_positions]).flatten.compact.map(&:tidy).reject(&:empty?)
                                          .reject { |pos| pos.include? 'Minister of State' } # TODO: include these
    end

    private

    def paragraphs
      # Get the immediately previous paragraphs,
      # but we only want the ones that have underlined text
      noko.xpath('preceding-sibling::*').slice_when { |node| node.name != 'p' }.to_a.last.map { |node| node.css('u') }
    end

    def line_positions
      paragraphs.drop(1).map(&:text).join(' ').tidy.split(/ AND (?=Minister)/)
    end

    # Sometimes the name line also includes a position
    def name_position
      nameline.split(',', 2)[1]
    end

    def positionless_name
      nameline.split(',').first.tidy
    end

    def nameline
      paragraphs.first.text.tidy
    end
  end

  class Members
    def member_container
      # each "block" is 2 or more <P>s followed by a <UL>
      # Get the <UL>, and then we can work back to get the Ps
      noko.xpath('.//p/following-sibling::*[1][name()="ul"]')
    end
  end
end

file = Pathname.new 'html/official.html'
puts EveryPoliticianScraper::FileData.new(file).csv
