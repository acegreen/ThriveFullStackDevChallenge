#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# Challenge: Process users and companies to generate token top-ups
# 
# This script reads users.json and companies.json files, processes active users
# belonging to companies, applies token top-ups, and generates an output.txt file
# with formatted results.

class TokenTopUpProcessor
  # Initialize the processor with file paths
  #
  # @param users_file [String] Path to users JSON file
  # @param companies_file [String] Path to companies JSON file
  # @param output_file [String] Path to output text file
  def initialize(users_file: 'users.json', companies_file: 'companies.json', output_file: 'output.txt')
    @users_file = users_file
    @companies_file = companies_file
    @output_file = output_file
  end

  # Main entry point to process files and generate output
  def process
    companies = load_companies
    users = load_users
    
    # Filter and process users
    processed_data = process_users_by_company(companies, users)
    
    # Generate output file
    generate_output(processed_data)
    
    puts "Successfully generated #{@output_file}"
  rescue StandardError => e
    $stderr.puts "Error: #{e.message}"
    $stderr.puts e.backtrace if ENV['DEBUG']
    exit 1
  end

  private

  # Load and parse companies JSON file
  #
  # @return [Hash] Hash with company id as key and company data as value
  def load_companies
    data = read_json_file(@companies_file)
    companies = {}
    
    data.each do |company|
      next unless valid_company?(company)
      
      companies[company['id']] = {
        id: company['id'],
        name: company['name'],
        top_up: company['top_up'],
        email_status: company['email_status']
      }
    end
    
    companies
  rescue JSON::ParserError => e
    raise "Invalid JSON in #{@companies_file}: #{e.message}"
  end

  # Load and parse users JSON file
  #
  # @return [Array] Array of user hashes
  def load_users
    data = read_json_file(@users_file)
    
    data.select { |user| valid_user?(user) }
  rescue JSON::ParserError => e
    raise "Invalid JSON in #{@users_file}: #{e.message}"
  end

  # Read and parse JSON file
  #
  # @param file_path [String] Path to JSON file
  # @return [Array, Hash] Parsed JSON data
  def read_json_file(file_path)
    unless File.exist?(file_path)
      raise "File not found: #{file_path}"
    end
    
    file_content = File.read(file_path)
    JSON.parse(file_content)
  end

  # Validate company data structure
  #
  # @param company [Hash] Company hash to validate
  # @return [Boolean] True if valid, false otherwise
  def valid_company?(company)
    return false unless company.is_a?(Hash)
    return false unless company['id'].is_a?(Numeric)
    return false unless company['name'].is_a?(String) && !company['name'].empty?
    return false unless company['top_up'].is_a?(Numeric)
    return false unless [true, false].include?(company['email_status'])
    
    true
  end

  # Validate user data structure
  #
  # @param user [Hash] User hash to validate
  # @return [Boolean] True if valid, false otherwise
  def valid_user?(user)
    return false unless user.is_a?(Hash)
    return false unless user['id'].is_a?(Numeric)
    return false unless user['first_name'].is_a?(String)
    return false unless user['last_name'].is_a?(String)
    return false unless user['email'].is_a?(String)
    return false unless user['company_id'].is_a?(Numeric)
    return false unless [true, false].include?(user['email_status'])
    return false unless [true, false].include?(user['active_status'])
    return false unless user['tokens'].is_a?(Numeric)
    
    true
  end

  # Process users grouped by company
  #
  # @param companies [Hash] Hash of companies by id
  # @param users [Array] Array of user hashes
  # @return [Hash] Processed data organized by company
  def process_users_by_company(companies, users)
    processed = {}
    
    users.each do |user|
      next unless user['active_status'] == true
      
      company_id = user['company_id']
      company = companies[company_id]
      
      # Skip users whose company is not in the companies file
      next unless company
      
      # Initialize company entry if needed
      processed[company_id] ||= {
        company: company,
        users_emailed: [],
        users_not_emailed: []
      }
      
      # Calculate new token balance
      previous_balance = user['tokens']
      top_up_amount = company[:top_up]
      new_balance = previous_balance + top_up_amount
      
      # Determine if user should be emailed
      should_email = company[:email_status] && user['email_status']
      
      user_data = {
        last_name: user['last_name'],
        first_name: user['first_name'],
        email: user['email'],
        previous_balance: previous_balance,
        new_balance: new_balance,
        top_up_amount: top_up_amount
      }
      
      if should_email
        processed[company_id][:users_emailed] << user_data
      else
        processed[company_id][:users_not_emailed] << user_data
      end
    end
    
    # Sort users by last name within each company
    processed.each do |_company_id, data|
      data[:users_emailed].sort_by! { |u| u[:last_name] }
      data[:users_not_emailed].sort_by! { |u| u[:last_name] }
    end
    
    processed
  end

  # Generate formatted output file
  #
  # @param processed_data [Hash] Processed data organized by company
  def generate_output(processed_data)
    File.open(@output_file, 'w') do |file|
      # Start with blank line
      file.puts ""
      
      # Sort companies by id
      sorted_companies = processed_data.sort_by { |company_id, _data| company_id }
      
      sorted_companies.each do |company_id, data|
        company = data[:company]
        
        file.puts "\tCompany Id: #{company[:id]}"
        file.puts "\tCompany Name: #{company[:name]}"
        file.puts "\tUsers Emailed:"
        
        if data[:users_emailed].empty?
          # No blank line when empty
        else
          data[:users_emailed].each do |user|
            file.puts "\t\t#{format_user_name(user)}"
            file.puts "\t\t  Previous Token Balance, #{user[:previous_balance]}"
            file.puts "\t\t  New Token Balance #{user[:new_balance]}"
          end
        end
        
        file.puts "\tUsers Not Emailed:"
        
        if data[:users_not_emailed].empty?
          file.puts ""
        else
          data[:users_not_emailed].each do |user|
            file.puts "\t\t#{format_user_name(user)}"
            file.puts "\t\t  Previous Token Balance, #{user[:previous_balance]}"
            file.puts "\t\t  New Token Balance #{user[:new_balance]}"
          end
        end
        
        # Calculate total top ups for this company
        total_top_ups = calculate_total_top_ups(data)
        file.puts "\t\tTotal amount of top ups for #{company[:name]}: #{total_top_ups}"
        file.puts ""
      end
    end
  end

  # Format user name as "Last, First, email"
  #
  # @param user [Hash] User data hash
  # @return [String] Formatted user name string
  def format_user_name(user)
    "#{user[:last_name]}, #{user[:first_name]}, #{user[:email]}"
  end

  # Calculate total top ups for a company
  #
  # @param data [Hash] Company data with users
  # @return [Integer] Total top up amount
  def calculate_total_top_ups(data)
    all_users = data[:users_emailed] + data[:users_not_emailed]
    all_users.sum { |user| user[:top_up_amount] }
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  processor = TokenTopUpProcessor.new
  processor.process
end

