#!/usr/bin/env ruby
#
#
# This handler formats alerts as Perspica events and sends them off to Perspica via the REST API
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
##
# {
#   "uuid": "flume-server-dc1",
#   "name": "flume-server1",
#   "timestamp": 1461323494551,
#   "type": "Service",
#   "datasourcename": "FlumeService",
#   "metrics": [
#     {
#       "description": "Total Put attempts (rate per 5 mins)",
#       "displayname": "flume:server:EventPutAttemptCount",
#       "kpi": "true",
#       "mlprocessing": "true",
#       "qualifienName": "perspica-flume-server-dc1-EventPutAttemptCount",
#       "units": "Number"
#       }
#   ],
#   "attributes": [
#     {
#       "name": "ModelTypes",
#       "value": "pca,univariate,mahalanobis"
#     }
#   ],
#   "samples": [
#     {
#       "metricid": "flume:server:EventPutAttemptCount",
#       "metricqualifiedname":"perspica-flume-server-dc1-EventPutAttemptCount",
#       "metricvalue": 1.8
#     }
#   ]
# }
##

require 'sensu-handler'

class PerspicaNotifier < Sensu::Handler
  def event_name
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def action_to_string
    @event['action'].eql?('resolve') ? 'RESOLVED' : 'ALERT'
  end

  def status_to_string
    case @event['check']['status']
    when 0
      'OK'
    when 1
      'WARNING'
    when 2
      'CRITICAL'
    else
      'UNKNOWN'
    end
  end

  def perspica_apikey
    settings['perspica']['apikey'] || ''
  end

  def perspica_apisecret
    settings['perspica']['apisecret'] || ''
  end

  def handle
    mail_to = build_mail_to_list
    body = <<-BODY.gsub(/^ {14}/, '')
            #{@event['check']['output']}
            Host: #{@event['client']['name']}
            Timestamp: #{Time.at(@event['check']['issued'])}
            Address:  #{@event['client']['address']}
            Check Name:  #{@event['check']['name']}
            Command:  #{@event['check']['command']}
            Status:  #{@event['check']['status']}
            Occurrences:  #{@event['occurrences']}
          BODY

    subject = if @event['check']['notification'].nil?
                "#{action_to_string} - #{event_name}: #{status_to_string}"
              else
                "#{action_to_string} - #{event_name}: #{@event['check']['notification']}"
              end

    puts 'subject: ' + subject + ' body: ' + body
    puts 'handled action: ' + @event['action'] + 'event ' + event_name

    rescue Timeout::Error
      puts 'mail -- timed out while attempting to ' + @event['action'] + ' an incident -- ' + event_name
    end
  end
end
