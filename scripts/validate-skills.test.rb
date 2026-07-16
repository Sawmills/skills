#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

VALIDATOR = File.expand_path("validate-skills", __dir__)

class ValidateSkillsTest < Minitest::Test
  def test_when_skill_is_valid_then_validator_passes
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill)

    status = run_validator(repo).last

    assert_predicate status, :success?
  end

  def test_when_skill_is_missing_frontmatter_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => "# No Frontmatter\n")

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "missing YAML frontmatter"
    refute_predicate status, :success?
  end

  def test_when_skill_is_missing_required_fields_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => "---\nname: demo\n---\n")

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "missing description"
    refute_predicate status, :success?
  end

  def test_when_skill_mentions_private_data_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill("tenant org_123"))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "private org identifier"
    refute_predicate status, :success?
  end

  def test_when_skill_has_markdown_extension_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation.md" => valid_skill)

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "skills must live at skills/<name>/SKILL.md"
    refute_predicate status, :success?
  end

  private

  def build_repo(files)
    Dir.mktmpdir.tap do |repo|
      files.each do |path, body|
        full_path = File.join(repo, path)
        FileUtils.mkdir_p(File.dirname(full_path))
        File.write(full_path, body)
      end
    end
  end

  def run_validator(repo)
    Open3.capture3(VALIDATOR, chdir: repo)
  end

  def valid_skill(body = "# Customer Knowledge Curation\n")
    <<~SKILL
      ---
      name: customer-knowledge-curation
      description: Use when using customer knowledge to build or maintain early-detection coverage.
      ---

      #{body}
    SKILL
  end
end
