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

## Performance Rewrite
The HTTP server for this service was rewritten so that Phoenix and it's dependencies were dropped and replaced with a plain old plug cowboy http server. The original Phoenix project was spun up using the following flags: `--no-assets --no-ecto --no-html --no-gettext --no-live --no-dashboard --no-mailer` so that this service would have as lean of an API as possible, but using Phoenix still came with a very large performance overhead cost.

By ripping out Phoenix and its dependencies, I saw about 90% faster API response times.

The original Phoenix version is in the branch `phoenix-version` if you'd like to test it out yourself.

| Endpoint | HTTP Server | Avg Response Time |
| :---     | :---:       | :---:             |
| GET /ping | Plug Cowboy | 104&mu;s         |
|           | Phoenix    | 1005&mu;s         |
| DELETE /ping | Plug Cowboy | 63&mu;s       |
|           | Phoenix     | 702&mu;s         |

## Further Work
- [x] Add `/ping/remove` endpoint which accepts a `name` parameter.
- [x] Performance tuning - speed up API by ditching Phoenix.
- [ ] Replace `:tesla` with `:req`
- [ ] Add an auth mechanism
- [ ] Address edge case in `/delete` when name doesn't exist
- [ ] Add guard for last_ping_timestamp (thinking of scenario where incoming timestamp is sooner that state timestamp)
- [ ] Tighten up logic around schedule changes
- [ ] Move state off of this service - maybe try out SQLite -> Fly's LiteFS.
- [ ] Add some automated CI/CD for testing/formatting/linting.
