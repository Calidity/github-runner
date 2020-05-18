#!/usr/bin/env ruby
require 'json'

GITHUB_OWNER = ENV['GITHUB_OWNER']
GITHUB_PAT   = ENV['GITHUB_PAT']
RUNNER_WORKDIR = ENV['RUNNER_WORKDIR']

registration_url = "https://api.github.com/orgs/#{GITHUB_OWNER}/actions/runners/registration-token"

puts "Requesting registration URL at '#{registration_url}'"

payload = `curl -sX POST -H "Authorization: token #{GITHUB_PAT}" #{registration_url}`

payload_parsed = JSON.parse(payload)

RUNNER_TOKEN = payload_parsed["token"]

system "./config.sh",
    "--name", `hostname`.chomp,
    "--token", RUNNER_TOKEN,
    "--work", RUNNER_WORKDIR,
    "--url", "https://github.com/#{GITHUB_OWNER}",
    "--unattended",
    "--replace"

def remove
    `./config.sh remove --unattended --token "#{RUNNER_TOKEN}"`
end

trap "SIGINT" do
    remove
    exit 130
end

trap "SIGTERM" do
    remove
    exit 143
end

pid = fork do
    exec "./run.sh"
end

Process.wait pid
