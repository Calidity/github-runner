#!/usr/bin/env ruby
require 'json'
require 'openssl'
require 'jwt'
require 'faraday'

GITHUB_OWNER = ENV['GITHUB_OWNER']
RUNNER_WORKDIR = ENV['RUNNER_WORKDIR']
GITHUB_APP_ID = ENV['GITHUB_APP_ID']

GITHUB_APP_CUSTOM_MEDIA_TYPE = 'application/vnd.github.machine-man-preview+json'

PRIVATE_KEY_PATH = '/certs/private-key'

def get_runner_token_with_token token
    registration_url = "https://api.github.com/orgs/#{GITHUB_OWNER}/actions/runners/registration-token"
    response = Faraday.post registration_url do |req|
        req.headers['Authorization'] = "Token #{token}"
    end
    puts "[-] POST #{registration_url}: #{response.status}"
    if response.status < 200 || response.status > 299
        puts "[!] Error: "
        p response.body
    end
    payload_parsed = JSON.parse(response.body)
    payload_parsed["token"]
end

def get_installation_id jwt
    response = Faraday.get "https://api.github.com/app/installations" do |req|
        req.headers['Authorization'] = "Bearer #{jwt}"
        req.headers['Accept'] = GITHUB_APP_CUSTOM_MEDIA_TYPE
    end
    puts "[-] GET https://api.github.com/app/installations: #{response.status}"
    if response.status < 200 || response.status > 299
        puts "[!] Error: "
        p response.body
    end
    payload_parsed = JSON.parse response.body
    payload_parsed[0]["id"]
end

def get_installation_access_token(installation_id, jwt)
    response = Faraday.post "https://api.github.com/app/installations/#{installation_id}/access_tokens" do |req|
        req.headers['Authorization'] = "Bearer #{jwt}"
        req.headers['Accept'] = GITHUB_APP_CUSTOM_MEDIA_TYPE
    end
    puts "[-] POST https://api.github.com/app/installations/#{installation_id}/access_tokens: #{response.status}"
    if response.status < 200 || response.status > 299
        puts "[!] Error: "
        p response.body
    end
    payload_parsed = JSON.parse response.body
    payload_parsed["token"]
end

def get_runner_token private_key_filename

    # 1. get the private key from storage
    puts "[+] Loading private key..."
    private_pem = File.read(private_key_filename)
    private_key = OpenSSL::PKey::RSA.new private_pem

    # 2. sign a JWT with that private key
    puts "[+] Creating JWT..."
    jwt_details = {
        iat: Time.now.to_i,
        exp: Time.now.to_i + (10 * 60),
        iss: GITHUB_APP_ID
    }

    jwt = JWT.encode(jwt_details, private_key, 'RS256')

    # 3. get the first installation's ID
    puts "[+] Loading installation ID..."
    installation_id = get_installation_id jwt

    # 4. get access token that grants access to an org that installed the app
    puts "[+] Creating an access token for the installation..."
    ins_acc_token = get_installation_access_token(installation_id, jwt)

    # 5. get runner authorization token from access token
    puts "[+] Creating runner token..."
    get_runner_token_with_token ins_acc_token
end

# To authenticate with a GitHub personal access token
RUNNER_TOKEN = get_runner_token_with_personal_token unless ENV['GITHUB_PAT'].empty?

# To authenticate with a GitHub App private key:
RUNNER_TOKEN = get_runner_token PRIVATE_KEY_PATH if ENV['GITHUB_PAT'].empty?

system "./config.sh",
    "--name", `hostname`.chomp,
    "--token", RUNNER_TOKEN,
    "--work", RUNNER_WORKDIR,
    "--url", "https://github.com/#{GITHUB_OWNER}",
    "--unattended",
    "--replace"

def remove
    `./bin/Runner.Listener remove --unattended --token "#{RUNNER_TOKEN}"`
end

trap "SIGINT" do
    puts "[+] Received SIGINT, shutting down..."
    remove
    exit 130
end

trap "SIGTERM" do
    puts "[+] Received SIGTERM, shutting down..."
    remove
    exit 143
end

pid = fork do
    exec "./run.sh"
end

Process.wait pid
