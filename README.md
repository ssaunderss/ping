## Background
This is an out of the box solution for ingesting periodic health pings from services that cannot expose a public HTTP endpoint - such as serverless webhooks, cron jobs, etc. This `ping` service receives pings with a service name, a frequency and optionally a timestamp. When this service receives a ping, it's expecting to receive another ping within the timeframe inferred from the frequency param - if it doesn't hear within that frequency, an alert will be sent to a downstream alerting service (which can be configured).

## Running Locally

I use `asdf` as my local package manager - to get up and running you'll need to run the following from the root of the directory:

```bash
# on mac
brew install asdf
asdf install 
```

Additionally, you'll need to set the following environment variable `PING_ALERT_URI` - this is the Alerts Service (AS) callback URI:
```bash
echo 'export PING_ALERT_URI="some.alert.service"' >> ~/.zshrc # or ~/.bashrc if you use bash
```

After that's set up run the following from the root of the project directory: 
```bash
mix deps.get && mix deps.compile
```

Now you'll be able to start up the server locally or run the tests using either of the following commands:
```bash
mix phx.server
mix test
```

## About the Ping Server

### `/ping`
The `/ping` endpoint accepts 3 parameters, 2 are necessary (`name`, `frequency`) and 1 is optional (`timestamp`), in the following example both are valid requests:

```bash
curl "127.0.0.1:4000/ping?name=test_service&frequency=10m"
curl "127.0.0.1:4000/ping?name=test_service&frequency=10m&timestamp=1664743905"
```

If a `timestamp` parameter is not given, a timestamp will be generated on insertion into the backend server.

The following are accepted as parameters:
- The `name` parameter is any valid string.
- The `frequency` parameter lets the service know how often it should be expecting a health ping. Valid formats are `#{integer}#{time_unit}`, with the following as valid time units - [`W`, `D`, `h`, `m`, `s`], representing [Weekly, Daily, Hourly, Minutely, Secondly] frequencies respectively. You can change frequencies on the fly - i.e. if I receive a ping at 10:00:00AM with a frequency of 1m, and then at 10:00:30AM I receive another ping from the same service with a frequency of 10m the service will expect the next ping to come at 10:10:30AM instead of 10:01:00AM.

For example, if we have a job called `daily_digest`. This job will call the ping service every time it is run as follows:

```
GET /ping?name=daily_digest&frequency=1D
```

Once the ping service receives this request, it should expect the subsequent request within the next day, failing to hear back within that timeframe an alert endpoint will be called. For local development you can set up your own webhook on [webhook.site](https://webhook.site) as the alert endpoint.

### `/ping/remove`

In the case that an upstream service becomes deprecated, there is an endpoint for removing that service from the internal monitoring system.

This endpoint accepts 1 parameter:
- `name` — the name of the service

For example, if we have a job called `daily_digest` and we deprecate this job (maybe in favor of a `weekly_digest` job) we no longer have a need to monitor this job because we're no longer expecting pings. To remove this job we could call:

```
GET /ping?name=daily_digest
```

## Further Work
- [ ] Add an auth mechanism
- [ ] Add `/ping/remove` endpoint which accepts a `name` parameter.
- [ ] Move state off of this service - maybe try out Fly's LiteFS.
- [ ] Add some automated CI/CD for testing/formatting/linting.

