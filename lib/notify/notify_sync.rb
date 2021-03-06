class NotifySync
  attr_writer :client

  API_KEY = Rails.application.credentials[:notify_api_key].freeze
  TEMPLATE_PATH = [Rails.root, "app", "notify", "notify_email"].freeze

  def compare
    remote_templates_copy = remote_templates.dup

    local_templates.each do |template_id, local_body|
      # check the remote template is present based on the local template's guid
      unless (rt = remote_templates_copy.delete(template_id))
        puts output_line(template_id, "Unknown", "Missing remote template")
        next
      end

      if local_body == reencode(rt.body)
        puts output_line(rt.id, rt.name, "Matches")
      else
        puts output_line(rt.id, rt.name, "Doesn't match")
      end
    end

    # Any templates remaining aren't present locally
    if remote_templates_copy.size.positive?
      remote_templates_copy.each do |_, template|
        puts output_line(template.id, template.name, "Missing local template")
      end
    end
  end

  def pull
    remote_templates.each do |template_id, rt|
      File.write(
        File.join(
          TEMPLATE_PATH,
          [rt.name.gsub(/[\ ]/, "").underscore, template_id, 'md'].join('.'),
        ),
        reencode(rt.body)
      )
    end
  end

private

  def output_line(template_id, template_name, status)
    [
      justify(template_id || "", 18),
      justify(template_name || "", 40),
      justify(status)
    ].join(" ")
  end

  def justify(str, amount = 20)
    str.ljust(amount)
  end

  # extract the body text, standardise newlines and chomp trailing lines
  def reencode(body)
    body.encode(body.encoding, universal_newline: true).chomp
  end

  def client
    @client ||= Notifications::Client.new(API_KEY)
  end

  def local_templates
    Dir.glob(File.join(TEMPLATE_PATH, "*.md")).each.with_object({}) do |path, hash|
      template_id = path.match(/\.(?<template_id>[A-z0-9\-]+)\.md$/)[:template_id]
      hash[template_id] = File.read(path).chomp
    end
  end

  def remote_templates
    client.get_all_templates.collection.index_by(&:id)
  end
end
