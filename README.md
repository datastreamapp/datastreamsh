<h1 align="center">
  <img src="https://raw.githubusercontent.com/datastreamapp/api-docs/main/docs/images/datastream.svg?sanitize=true" alt="DataStream Logo" width="400">
  <br/>
  DataStream.sh
  <br/>
  <br/>
</h1>
<p align="center">
  DataStream.org API helper. See <a href="https://github.com/datastreamapp/api-docs/tree/main/docs">API documentation</a> for query string values and structure.
</p>

## Install (MacOS)

```bash
curl -o /usr/local/bin/datastreamsh https://raw.githubusercontent.com/datastreamapp/datastreamsh/main/datastream.sh
chmod +x /usr/local/bin/datastreamsh
```

## Use

This package has been tested on MacOS.

```
datastreamsh command [options...]
```

### Commands

- `setup`: Prompts for API key, will be save to `~/.datastream` in plain text. Not setting up will prompt for `x-api-key` on ever command.
- `metadata`: Wraps /v1/odata/v4/Metadata API endpoint
- `locations`: Wraps /v1/odata/v4/Locations API endpoint
- `observations`: Wraps /v1/odata/v4/Observations API endpoint
- `records`: Wraps /v1/odata/v4/Records API endpoint

### Options

- `--select`: What parameters to be returned
- `--filter`: What you want to , in OData format
- `--format`: Print output in alternative format (Allowed: `JSONSTREAM`, `CSV`; Default: `JSONSTREAM`)
- `--top`: Number of results to return per request (Default: 10000)
- `--domain`: Use to point at testing environments

### Example: Setup

```bash
# datastreamsh setup
$ datastreamsh setup
x-api-key: # copy and paste API key here and press enter
```

### Example: Basic

```bash
# datastreamsh command [options...]
$ datastreamsh locations --select "..." --filter "..."
```

### Example: save as CSV to file

```bash
# datastreamsh command --format CSV --select <select> [options...]
$ datastreamsh records --format CSV --select "..." --filter "..." > file.csv
```
