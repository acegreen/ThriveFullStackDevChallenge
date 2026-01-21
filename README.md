# Token Top-Up Processor

A Ruby script that processes user and company data to apply token top-ups and generate formatted output reports.

## Overview

This script reads JSON files containing user and company data, processes active users belonging to companies, applies token top-ups based on company settings, and generates a formatted output file indicating which users were emailed and which were not.

## Requirements

- Ruby (tested with Ruby 2.7+, should work with any modern Ruby version)
- No external dependencies (uses only Ruby standard library)

## Files

- `challenge.rb` - Main Ruby script
- `users.json` - Input file containing user data
- `companies.json` - Input file containing company data
- `output.txt` - Generated output file (created when script runs)
- `example_output.txt` - Example of expected output format

## Usage

Run the script from the command line:

```bash
ruby challenge.rb
```

The script will:
1. Read `users.json` and `companies.json` from the current directory
2. Process active users belonging to companies
3. Generate `output.txt` with formatted results

### Making the script executable (optional)

You can also make the script executable and run it directly:

```bash
chmod +x challenge.rb
./challenge.rb
```

## How It Works

### Processing Logic

1. **User Filtering**: Only processes users where:
   - `active_status` is `true`
   - User's `company_id` exists in the companies file

2. **Token Top-Up**: For each qualifying user:
   - Adds the company's `top_up` amount to the user's current token balance
   - Calculates the new token balance

3. **Email Status**: Determines if a user should be emailed:
   - User is emailed if **both**:
     - Company's `email_status` is `true`
     - User's `email_status` is `true`
   - Otherwise, user is not emailed

4. **Sorting**:
   - Companies are sorted by `id` (ascending)
   - Users are sorted alphabetically by `last_name` within each company

### Output Format

The output file contains:
- Company information (ID and name)
- List of users who were emailed (with token balances)
- List of users who were not emailed (with token balances)
- Total top-up amount per company

## Error Handling

The script includes robust error handling for:
- Missing input files
- Invalid JSON format
- Malformed or incomplete data
- Invalid data types

Invalid records are silently skipped during processing. If critical errors occur (e.g., file not found, invalid JSON), the script will display an error message and exit with status code 1.

### Debug Mode

To see detailed error traces, run with the `DEBUG` environment variable:

```bash
DEBUG=1 ruby challenge.rb
```

## Data Validation

The script validates data before processing:

**Company validation** requires:
- `id`: Numeric value
- `name`: Non-empty string
- `top_up`: Numeric value
- `email_status`: Boolean value

**User validation** requires:
- `id`: Numeric value
- `first_name`: String
- `last_name`: String
- `email`: String
- `company_id`: Numeric value
- `email_status`: Boolean value
- `active_status`: Boolean value
- `tokens`: Numeric value

Invalid records are skipped during processing.

## Example

Given the example data files, running the script will generate an `output.txt` file that matches the format shown in `example_output.txt`.

## Code Structure

The script is organized into a `TokenTopUpProcessor` class with the following responsibilities:

- **Data Loading**: Reads and parses JSON files
- **Data Validation**: Validates company and user records
- **Business Logic**: Processes users, applies top-ups, determines email status
- **Output Generation**: Formats and writes the output file

## Testing

To verify the script works correctly, compare the generated `output.txt` with `example_output.txt`:

```bash
diff example_output.txt output.txt
```

If the files match (or only differ by whitespace), the script is working correctly.

## License

This code was created as part of a coding challenge.

