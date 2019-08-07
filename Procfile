web: bundle exec rails server -p $PORT
resque: env QUEUE=critical,high,default,abuse_reports,ahoy,billing,delete,images,import,intercom,mailer,mailers,recurring,reviews,searchkick,seed,sync,low TERM_CHILD=1 INTERVAL=0.1 RESQUE_PRE_SHUTDOWN_TIMEOUT=20 RESQUE_TERM_TIMEOUT=8 bundle exec rake environment resque:work
scheduler: bundle exec rake environment resque:scheduler
worker: bundle exec sidekiq -C config/sidekiq.yml
release: bash ./bin/release.sh
