#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8
# v2024-12-02
require_relative 'constants'

class Collapser
  attr_accessor :compress_ids, :expand_ids, :options

  def initialize(
    collapsed_level: nil,
    collapsible_types: COLLAPSIBLE_TYPES,
    compress_ids:,
    expand_ids:,
    options: {}
  )
    @collapsed_level = collapsed_level
    @collapsible_types = collapsible_types.dup
    @options = options.dup
    @compress_ids = compress_ids # by ref, user action
    @expand_ids = expand_ids # by ref, user action
  end

  def collapse_per_options?(fcb, options: @options)
    criteria = options[:"#{fcb.type}#{fcb.level}_collapse"]
    return false if criteria.nil?

    criteria
  end

  # collapse per user action
  def collapse_per_state?(fcb, default: false)
    if @compress_ids.key?(fcb.id) && !!@compress_ids[fcb.id]
      true
    elsif @expand_ids.key?(fcb.id) && !!@expand_ids[fcb.id]
      false
    else
      default
    end
  end

  def collapse_per_token?(fcb)
    fcb.token == COLLAPSIBLE_TOKEN_COLLAPSE
  end

  def collapsible_per_options?(fcb, options: @options)
    criteria = options[:"#{fcb.type}#{fcb.level}_collapsible"]
    return false if criteria.nil?

    criteria
  end

  def collapsible_per_type?(fcb, collapsible_types: @collapsible_types)
    @collapsible_types.nil? || @collapsible_types.include?(fcb.type)
  end

  def collapse?(fcb, initialize: false)
    per_options_and_token = (collapse_per_options?(fcb) || collapse_per_token?(fcb)) && !expand_per_token?(fcb)
    if initialize
      per_options_and_token
    else
      collapse_per_state?(fcb, default: per_options_and_token)
    end
  end

  def collapsible?(fcb)
    collapsible_per_options?(fcb)
  end

  def expand_per_token?(fcb)
    fcb.token == COLLAPSIBLE_TOKEN_EXPAND
  end

  def hide?(fcb,
            collapsed_level: @collapsed_level,
            collapsible_types: @collapsible_types,
            initialize: true)

    fcb.collapsible = collapsible?(fcb)
    if collapsed_level.nil?
      # is not collapsing
      fcb.collapse = collapse?(fcb, initialize: initialize)
      collapsed_level = fcb.level if fcb.collapse
      fcb.hide = false

    elsif fcb.level.nil?
      fcb.hide = true

    elsif fcb.level > collapsed_level
      # Currently collapsed; evaluate for the current block
      fcb.collapse = collapse?(fcb, initialize: initialize)
      collapsed_level = fcb.level if fcb.collapse
      fcb.hide = true # block is at a deeper level thus hidden

    elsif fcb.collapsible
      # Currently expanded; evaluate for the current block
      fcb.collapse = collapse?(fcb, initialize: initialize)
      collapsed_level = fcb.collapse ? fcb.level : nil
      fcb.hide = false
    elsif collapsible_per_type?(fcb)
      fcb.collapsible = false
      fcb.collapse = false
      fcb.hide = false
    else
      fcb.hide = true
    end
    if fcb.collapse
      @compress_ids[fcb.id] = fcb.level
      @expand_ids.delete(fcb.id)
    else
      @compress_ids.delete(fcb.id)
      @expand_ids[fcb.id] = fcb.level
    end
    collapsed_level
  end

  # Reject rows that should be hidden based on the hierarchy
  def reject(fcbs, initialize: true, &block)
    analyze(fcbs, initialize: initialize, reject: true, &block)
  end

  # Reject rows that should be hidden based on the hierarchy
  def analyze(fcbs, initialize: true, reject: false, &block)
    fcbs.reject do |fcb|
      @collapsed_level = hide?(fcb, initialize: initialize)
      block.call fcb, @collapsed_level if block

      reject && fcb.hide
    end
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'
require_relative 'ww'

# Updated FCB struct with an id for testing
FCB = Struct.new(:id, :type, :level, :token, :collapse, :collapsible, :hide)
OPTIONS = {
  divider4_collapse: false,
  divider4_collapsible: true,
  heading1_collapse: false,
  heading1_collapsible: false,
  heading2_collapse: true,
  heading2_collapsible: true,
  heading3_collapse: false,
  heading3_collapsible: true
}.freeze

class CollapserTest < Minitest::Test
  def setup
    @collapser = Collapser.new(
      collapsible_types: COLLAPSIBLE_TYPES.dup,
      options: OPTIONS.dup,
      compress_ids: {},
      expand_ids: {}
    ).dup
  end

  def test_analyze
    # Define test scenarios as arrays of FCB objects and expected filtered results

    # :id, :type, :level, :token (in order for FCB.new)
    ff_h1a = ['h1a', 'heading', 1, '']
    ff_h1b = ['h1b', 'heading', 1, '']
    ff_h2a = ['h2a', 'heading', 2, '']
    ff_h2b = ['h2b', 'heading', 2, '']
    ff_t1 = ['t1', 'text', nil, '']
    ff_t2 = ['t2', 'text', nil, '']
    ff_t3 = ['t3', 'text', nil, '']
    ff_t4 = ['t4', 'text', nil, '']
    ff_h1a_collapse = ['h1a', 'heading', 1, COLLAPSIBLE_TOKEN_COLLAPSE]
    ff_h1a_expand = ['h1a', 'heading', 1, COLLAPSIBLE_TOKEN_EXPAND]
    ff_h1b_expand = ['h1b', 'heading', 1, COLLAPSIBLE_TOKEN_EXPAND]
    ff_h2a_collapse = ['h2a', 'heading', 2, COLLAPSIBLE_TOKEN_COLLAPSE]
    ff_h2b_collapse = ['h2b', 'heading', 2, COLLAPSIBLE_TOKEN_COLLAPSE]

    # :collapse, :collapsible, :hide (in order for FCB.new)
    cc_init = [false, false, false]
    cc_collapse = [true, false, false]
    cc_collapse_collapsible = [true, true, false]
    cc_collapsible = [false, true, false]
    cc_collapsible_hide = [false, true, true]
    cc_hide = [false, false, true]
    cc_undefined_hide = [nil, nil, false]

    fc_h1a__collapse = FCB.new(*ff_h1a, *cc_collapse)
    fc_h1a__collapse_collapsible = FCB.new(*ff_h1a, *cc_collapse_collapsible)
    fc_h1a__collapsed_init = FCB.new(*ff_h1a_collapse, *cc_init)
    fc_h1a__collapsible = FCB.new(*ff_h1a, *cc_collapsible)
    fc_h1a__collapsible_hide = FCB.new(*ff_h1a, *cc_collapsible_hide)
    fc_h1a__expanded_init = FCB.new(*ff_h1a_expand, *cc_init)
    fc_h1a__init = FCB.new(*ff_h1a, *cc_init)

    fc_h1b__init = FCB.new(*ff_h1b, *cc_init)

    fc_h2a__collapse = FCB.new(*ff_h2a, *cc_collapse)
    fc_h2a__collapse_collapsible = FCB.new(*ff_h2a, *cc_collapse_collapsible)
    fc_h2a__collapsed_collapsible = FCB.new(*ff_h2a_collapse, *cc_collapsible)
    fc_h2a__collapsible = FCB.new(*ff_h2a, *cc_collapsible)
    fc_h2a__hide = FCB.new(*ff_h2a, *cc_hide)
    fc_h2a__init = FCB.new(*ff_h2a, *cc_init)

    fc_h2b__init = FCB.new(*ff_h2b, *cc_init)

    fc_t1__hide = FCB.new(*ff_t1, *cc_hide)
    fc_t1__init = FCB.new(*ff_t1, *cc_init)
    fc_t2__hide = FCB.new(*ff_t2, *cc_hide)
    fc_t2__init = FCB.new(*ff_t2, *cc_init)
    fc_t3__init = FCB.new(*ff_t3, *cc_init)
    fc_t4__hide = FCB.new(*ff_t4, *cc_hide)
    fc_t4__init = FCB.new(*ff_t4, *cc_init)

    analyze_cases = {
      with_token: [
        { name: 'collapse',
          fcbs: [fc_h1a__collapsed_init],
          expected: [FCB.new(*ff_h1a_collapse, *cc_collapse)] },
        { name: 'expand',
          fcbs: [fc_h1a__expanded_init],
          expected: [fc_h1a__expanded_init] },
        { name: 'collapse, against options',
          fcbs: [fc_h1a__collapsed_init],
          options: { heading1_collapse: false },
          expected: [FCB.new(*ff_h1a_collapse, *cc_collapse)] },
        { name: 'expand, against options',
          fcbs: [fc_h1a__expanded_init],
          options: { heading1_collapse: true },
          expected: [fc_h1a__expanded_init] }
      ],

      with_no_state: [
        { name: 'heading2_collapse',
          fcbs: [
            fc_h1a__init,
            fc_h2a__init,
            fc_h1b__init,
            fc_h2b__init
          ],
          options: { heading2_collapse: true },
          expected: [
            fc_h1a__init,
            fc_h2a__collapse, # s/b fc_h2a__collapse_collapsible, ok for test
            fc_h1b__init,
            fc_h2b__init # s/b fc_h2b__collapse_collapsible, ok for test
          ] },

        { name: 'hide subsections',
          fcbs: [
            fc_h1a__init, fc_t1__init,
            fc_h2a__init, fc_t2__init,
            fc_h1b__init, fc_t3__init,
            fc_h2b__init, fc_t4__init
          ],
          options: { heading2_collapse: true },
          expected: [
            fc_h1a__init, fc_t1__init,
            fc_h2a__collapse, fc_t2__hide,
            fc_h1b__init, fc_t3__init,
            fc_h2b__init, fc_t4__hide
          ] },

        { name: 'not collapsible',
          fcbs: [fc_h1a__init],
          options: {},
          expected: [fc_h1a__init] },

        { name: 'collapse, not collapsible',
          fcbs: [fc_h1a__init],
          options: { heading1_collapse: true },
          expected: [fc_h1a__collapse] },

        { name: 'collapsible, not collapsed',
          fcbs: [fc_h1a__init],
          options: { heading1_collapsible: true },
          expected: [fc_h1a__collapsible] },

        { name: 'collapsible, not collapsed, with a dependent',
          fcbs: [fc_h1a__init, fc_t1__init],
          options: { heading1_collapsible: true },
          expected: [fc_h1a__init, fc_t1__init] },

        { name: 'collapsible, collapsed',
          fcbs: [fc_h1a__init],
          options: { heading1_collapse: true,
                     heading1_collapsible: true },
          expected: [fc_h1a__collapse_collapsible] },

        { name: 'collapsible, collapsed, with a dependent',
          fcbs: [fc_h1a__init, fc_t1__init],
          options: { heading1_collapse: true,
                     heading1_collapsible: true },
          expected: [fc_h1a__collapse_collapsible,
                     fc_t1__hide] },

        { name: 'collapsible, collapsed, with a dependent and lower levels',
          fcbs: [fc_h1a__init, fc_t1__init, fc_h2a__init],
          options: { heading1_collapse: true,
                     heading1_collapsible: true },
          expected: [fc_h1a__collapse_collapsible,
                     fc_t1__hide,
                     fc_h2a__hide] },

        { name: 'collapsible, collapsed, with a dependent and higher levels',
          fcbs: [fc_h1a__init, fc_h2a__init, fc_t1__init],
          options: { heading2_collapse: true,
                     heading2_collapsible: true },
          expected: [fc_h1a__init,
                     fc_h2a__collapse_collapsible,
                     fc_t1__hide] }
      ],

      with_empty_state: [
        { name: 'expanded remains expanded',
          fcbs: [fc_h1a__init],
          options: { heading1_collapsible: true },
          initialize: false,
          expected: [fc_h1a__collapsible] }
      ],

      with_collapsed_state: [
        { name: 'collapsed remains collapsed',
          fcbs: [fc_h1a__collapse_collapsible],
          options: { heading1_collapsible: true },
          compress_ids: { 'h1a' => 1 },
          expand_ids: {},
          initialize: false,
          expected: [fc_h1a__collapse_collapsible] }
      ]
    }

    analyze_cases.each do |name, test_cases|
      test_cases.each_with_index do |test_case, index|
        @collapser = Collapser.new(
          collapsed_level: test_case[:collapsed_level],
          collapsible_types: test_case[:collapsible_types] || COLLAPSIBLE_TYPES,
          options: (test_case[:options] || OPTIONS).dup,
          compress_ids: test_case[:compress_ids] || {},
          expand_ids: {}
        )
        analysis = @collapser.analyze(
          test_case[:fcbs],
          initialize: test_case[:initialize].nil? ? true : test_case[:initialize]
        )
        assert_equal test_case[:expected], analysis,
                     "Failed on test case #{index + 1} #{name} #{test_case[:name]}"
      end
    end
  end
end
