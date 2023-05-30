# Network Statistics Microservice

This is a microservice written in Ruby that collects network statistics over a provided target. It accepts input data as JSON via HTTP POST requests and measures the response times of multiple endpoints. The microservice calculates the minimum, maximum, and average response times for each endpoint and provides a summary of the statistics.

## Getting Started

### Prerequisites

- Ruby (version 3.2.1 or higher)
- Bundler (for installing dependencies)
- Docker (optional, for containerization)
- Make (optional, for using the Makefile commands)


### Installation 

1. Clone this repository to your local machine.
2. Install the necessary dependencies by running the following command:

```bash
bundle install
```

### Usage
Start the microservice by running the following command

#### Manually
```bash
ruby main.rb
```

Can ran microservice in docker container via make
```bash
make build; make
```


The microservice will listen on http://localhost:4567.

Send a POST request to http://localhost:4567 with the JSON input data. The microservice will process the data and return the collected network statistics as a JSON response.

Example JSON input:

```json
{
  "endpoints": [
    {
      "method": "POST",
      "url": "http://example.com/info",
      "headers": [
        {
          "name": "Cookie",
          "value": "token=DEADCAFE"
        }
      ],
      "body": "hello"
    }
  ],
  "num_requests": 5,
  "retry_failed": false
}
```

Example JSON response:

```json
{
  "endpoints": [
    {
      "min": 10,
      "max": 20,
      "avg": 12,
      "fails": 1
    }
  ],
  "summary": {
    "min": 10,
    "max": 20,
    "avg": 12,
    "fails": 1
  }
}
```
### Running Tests
You can run the tests either using RSpec directly or using the provided Makefile commands.

Using RSpec
Make sure you have RSpec installed. If not, install it by running:

```bash
 gem install rspec
```

```bash
rspec
```
The tests will run, and the test results will be displayed.

### Using Makefile Commands
Make sure you have Make installed. If not, install it based on your operating system.

The following Makefile commands are available:

`all` (default): The default target is run, so running make alone is equivalent to make run.
`build`: Builds the Docker image based on the Dockerfile.
`run`: Builds the Docker image (if not already built) and runs the Docker container in detached mode.
`stop`: Stops and removes the running Docker container.
`test`: Runs the tests using RSpec.
`clean`: Cleans the SQLite database file.
`clean-all`: Cleans the SQLite database file, stops and removes the Docker container.
To use the Makefile commands, open a terminal and navigate to the project directory. Then, you can run the commands by entering make <command>.

