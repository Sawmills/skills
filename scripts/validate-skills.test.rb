#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

VALIDATOR = File.expand_path("validate-skills", __dir__)
REPO_ROOT = File.expand_path("..", __dir__)

class ValidateSkillsTest < Minitest::Test
  def test_current_repository_is_valid
    stderr, status = run_validator(REPO_ROOT).values_at(1, 2)

    assert_predicate status, :success?, stderr
  end

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

  def test_when_frontmatter_has_extra_keys_then_validator_fails
    repo = build_repo(
      "skills/customer-knowledge-curation/SKILL.md" => <<~SKILL
        ---
        name: customer-knowledge-curation
        description: Use when using customer knowledge.
        version: 1
        ---

        # Customer Knowledge Curation
      SKILL
    )

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "frontmatter supports only name and description"
    refute_predicate status, :success?
  end

  def test_when_skill_name_does_not_match_directory_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill.sub("customer-knowledge-curation", "other-skill"))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "name must match directory customer-knowledge-curation"
    refute_predicate status, :success?
  end

  def test_when_skill_name_has_invalid_characters_then_validator_fails
    repo = build_repo(
      "skills/customer-knowledge-curation/SKILL.md" => valid_skill.sub("customer-knowledge-curation", "Customer Knowledge")
    )

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "name must be lowercase letters, numbers, and hyphens"
    refute_predicate status, :success?
  end

  def test_when_description_does_not_start_with_use_when_then_validator_fails
    repo = build_repo(
      "skills/customer-knowledge-curation/SKILL.md" => valid_skill.sub("Use when using customer knowledge.", "Helps with customer knowledge.")
    )

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "description must start with 'Use when'"
    refute_predicate status, :success?
  end

  def test_when_skill_mentions_private_data_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill("tenant org_123"))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "private org identifier"
    refute_predicate status, :success?
  end

  def test_when_reference_mentions_internal_ticket_then_validator_fails
    repo = build_repo(
      "skills/customer-knowledge-curation/SKILL.md" => valid_skill("See [references/details.md](references/details.md)."),
      "skills/customer-knowledge-curation/references/details.md" => "# Details\n\nSAW-1234\n"
    )

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "internal ticket identifier"
    refute_predicate status, :success?
  end

  def test_when_customer_name_is_present_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill("BigID example"))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "private customer name"
    refute_predicate status, :success?
  end

  def test_when_private_bootstrap_detail_is_present_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill("bootstrap workflow"))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "private bootstrap workflow detail"
    refute_predicate status, :success?
  end

  def test_when_skill_has_markdown_extension_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation.md" => valid_skill)

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "skills must live at skills/<name>/SKILL.md"
    refute_predicate status, :success?
  end

  def test_when_skill_links_missing_reference_then_validator_fails
    repo = build_repo(
      "skills/customer-knowledge-curation/SKILL.md" => valid_skill("See [references/missing.md](references/missing.md).")
    )

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "missing referenced file references/missing.md"
    refute_predicate status, :success?
  end

  def test_when_skill_link_escapes_skill_directory_then_validator_fails
    repo = build_repo(
      "skills/customer-knowledge-curation/SKILL.md" => valid_skill("See [escape](../escape.md)."),
      "skills/escape.md" => "# Escape\n"
    )

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "markdown reference links must be relative"
    refute_predicate status, :success?
  end

  def test_when_reference_file_is_unlinked_then_validator_fails
    repo = build_repo(
      "skills/customer-knowledge-curation/SKILL.md" => valid_skill,
      "skills/customer-knowledge-curation/references/details.md" => "# Details\n"
    )

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "reference file must be linked directly from SKILL.md"
    refute_predicate status, :success?
  end

  def test_when_reference_links_another_markdown_file_then_validator_fails
    repo = build_repo(
      "skills/customer-knowledge-curation/SKILL.md" => valid_skill("See [references/details.md](references/details.md)."),
      "skills/customer-knowledge-curation/references/details.md" => "# Details\n\nSee [more](more.md).\n",
      "skills/customer-knowledge-curation/references/more.md" => "# More\n"
    )

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "reference files must not link to other markdown files"
    refute_predicate status, :success?
  end

  def test_when_skill_is_too_long_then_validator_fails
    long_body = (["# Customer Knowledge Curation"] + Array.new(501, "line")).join("\n")
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill(long_body))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "SKILL.md must be 500 lines or fewer"
    refute_predicate status, :success?
  end

  def test_when_authenticated_v1_conditions_crud_is_documented_then_validator_allows_it
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill(<<~BODY))
      `GET /v1/conditions`
      `GET /v1/conditions/:id`
      `POST /v1/conditions`
      `PUT /v1/conditions/:id`
      `DELETE /v1/conditions/:id`
    BODY

    status = run_validator(repo).last

    assert_predicate status, :success?
  end

  def test_when_conditions_id_get_is_documented_then_validator_allows_it
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill("Run `GET /v1/conditions/:id` to verify."))

    status = run_validator(repo).last

    assert_predicate status, :success?
  end

  def test_when_legacy_conditions_api_is_documented_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill("Run `POST /api/conditions`."))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "legacy /api/conditions is not customer-facing"
    refute_predicate status, :success?
  end

  def test_when_v1_conditions_query_selects_org_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill("Run `GET /v1/conditions?org=acme`."))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "Conditions organization comes from authenticated context"
    refute_predicate status, :success?
  end

  def test_when_condition_body_contains_org_then_validator_fails
    body = "`POST /v1/conditions`\n```json\n{ \"org\": \"acme\", \"id\": \"checkout\" }\n```"
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill(body))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "condition bodies must not select an organization"
    refute_predicate status, :success?
  end

  def test_when_unrelated_json_contains_org_then_validator_allows_it
    body = <<~BODY
      `POST /v1/conditions`
      ```json
      { "id": "checkout" }
      ```

      Unrelated response metadata:
      ```json
      { "org": "display-only" }
      ```
    BODY
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill(body))

    status = run_validator(repo).last

    assert_predicate status, :success?
  end

  def test_current_skill_documents_complete_authenticated_v1_crud
    body = File.read(File.join(REPO_ROOT, "skills/customer-knowledge-curation/SKILL.md"))
    reference = File.read(File.join(REPO_ROOT, "skills/customer-knowledge-curation/references/conditions-api.md"))
    contract = "#{body}\n#{reference}"

    assert_match(%r{GET\s+/v1/conditions(?=[\s`]|$)}, contract)
    assert_match(%r{GET\s+/v1/conditions/:id(?=[\s`]|$)}, contract)
    assert_match(%r{POST\s+/v1/conditions(?=[\s`]|$)}, contract)
    assert_match(%r{PUT\s+/v1/conditions/:id(?=[\s`]|$)}, contract)
    assert_match(%r{DELETE\s+/v1/conditions/:id(?=[\s`]|$)}, contract)
    assert_match(/authenticated customer context/, contract)
    refute_match(%r{/api/conditions|/v1/conditions\?org=}, contract)
  end

  def test_when_context_evidence_is_documented_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill("Record details in `context.evidence`."))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "context.evidence is not accepted by the Conditions API"
    refute_predicate status, :success?
  end

  def test_when_evidence_json_field_is_documented_then_validator_fails
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill('{ "context": { "evidence": "baseline" } }'))

    stderr, status = run_validator(repo).values_at(1, 2)

    assert_includes stderr, "context.evidence is not accepted by the Conditions API"
    refute_predicate status, :success?
  end

  def test_when_unrelated_evidence_json_field_is_documented_then_validator_allows_it
    repo = build_repo("skills/customer-knowledge-curation/SKILL.md" => valid_skill('{ "evidence": "valid for another API" }'))

    status = run_validator(repo).last

    assert_predicate status, :success?
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
      description: Use when using customer knowledge.
      ---

      #{body}
    SKILL
  end
end
