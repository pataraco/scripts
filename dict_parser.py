#!/usr/bin/env python

from __future__ import print_function
import ast
import json

event = {u'Records': [{u'EventVersion': u'1.0', u'EventSubscriptionArn': u'arn:aws:sns:us-east-1:448472785679:PA-Failure:02a48004-6777-4712-8df5-f6ed3ab3908c', u'EventSource': u'aws:sns', u'Sns': {u'SignatureVersion': u'1', u'Timestamp': u'2018-05-16T02:03:17.673Z', u'Signature': u'g4TneA7XxNveVVy5egNjV2dRRXW/K1J3VA8PDnxCKjdEOdstnA+BfF5nYc7Xt1Jhvixlwoou0hKKKcRRnyYpxQVVjBAxv9SF0LUtuaOxTP5Jcod8QbkzLZJ8b7tbQ8ZpL2Edz2DnprMET45Br0e8aM4i9GRgYTRhtIgB1mptZA4cQWeyiz0GdUk6LoMBmFjTwUs1lY3RaoN1qeg2Pd3Zxlr0fplqmtC7UZgbHNH0yKZjNnoQB+wbAjFnXt+eTg+tntt6WCtN60axKq9holyeIgDHUpUfKiwPDvPa9BYrjY04m7wzWFsKNyW/PuFtU4KbJjNc0JJ6Br62EQ3c5KVBLQ==', u'SigningCertUrl': u'https://sns.us-east-1.amazonaws.com/SimpleNotificationService-eaea6120e66ea12e88dcd8bcbddca752.pem', u'MessageId': u'7a008643-3ee2-533a-930a-d536ad4789e6', u'Message': u'{"AlarmName":"pa-status-failed","AlarmDescription":null,"AWSAccountId":"448472785679","NewStateValue":"ALARM","NewStateReason":"Threshold Crossed: 1 out of the last 1 datapoints [0.0 (16/05/18 02:01:00)] was greater than or equal to the threshold (0.0) (minimum 1 datapoint for OK -> ALARM transition).","StateChangeTime":"2018-05-16T02:03:17.629+0000","Region":"US East (N. Virginia)","OldStateValue":"OK","Trigger":{"MetricName":"StatusCheckFailed","Namespace":"AWS/EC2","StatisticType":"Statistic","Statistic":"MINIMUM","Unit":null,"Dimensions":[{"name":"InstanceId","value":"i-0988f10c91115339a"}],"Period":60,"EvaluationPeriods":1,"ComparisonOperator":"GreaterThanOrEqualToThreshold","Threshold":0.0,"TreatMissingData":"","EvaluateLowSampleCountPercentile":""}}', u'MessageAttributes': {}, u'Type': u'Notification', u'UnsubscribeUrl': u'https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:448472785679:PA-Failure:02a48004-6777-4712-8df5-f6ed3ab3908c', u'TopicArn': u'arn:aws:sns:us-east-1:448472785679:PA-Failure', u'Subject': u'Status Check Alarm: "pa-status-failed" in US East (N. Virginia)'}}]}

# event = {'Records': [{'EventVersion': '1.0', 'EventSubscriptionArn': 'arn:aws:sns:us-east-1:448472785679:PA-Failure:02a48004-6777-4712-8df5-f6ed3ab3908c', 'EventSource': 'aws:sns', 'Sns': {'SignatureVersion': '1', 'Timestamp': '2018-05-15T20:30:38.815Z', 'Signature': 'qozcFyw5G4anP+uWBfwkQFXGD6yq21S7nIuFqxym+p6qgImUyIu7p0P/Ldba8CCeZ6CO4mOW/GvVfjHp9RfTQHFVZAWWwXfNfaz0G9c6justyoRmTaEFPqBnbrri5QWnulaJHR6YZiOq8WTOwvCY0RG56vJPRuLRO1A4NJK6VxAspa0627F0+Rb6aO4WWxvVmBc0wLyyJEL5Os+xNVYgW1sAANDBPG/b/SI6wxXMFqSDFdNQ1TlovZaRgw4bEFLGS87324XkF0dcOF+1igar5+OGbTNx7GM5asAx30KkNAe2HymMBK9sWX7jinG/aRc+ORZFqjIvc13JFsClcrcbww==', 'SigningCertUrl': 'https://sns.us-east-1.amazonaws.com/SimpleNotificationService-eaea6120e66ea12e88dcd8bcbddca752.pem', 'MessageId': '14987858-d28a-551c-b37e-2b2d9724c3c4', 'Message': '{"AlarmName":"pa-status-failed","AlarmDescription":"","AWSAccountId":"448472785679","NewStateValue":"ALARM","NewStateReason":"Threshold Crossed: 1 out of the last 1 datapoints [0.0 (15/05/18 20:25:00)] was greater than or equal to the threshold (0.0) (minimum 1 datapoint for OK -> ALARM transition).","StateChangeTime":"2018-05-15T20:30:38.776+0000","Region":"US East (N. Virginia)","OldStateValue":"INSUFFICIENT_DATA","Trigger":{"MetricName":"StatusCheckFailed_Instance","Namespace":"AWS/EC2","StatisticType":"Statistic","Statistic":"AVERAGE","Unit":"","Dimensions":[{"name":"InstanceId","value":"i-0988f10c91115339a"}],"Period":300,"EvaluationPeriods":1,"ComparisonOperator":"GreaterThanOrEqualToThreshold","Threshold":0.0,"TreatMissingData":"","EvaluateLowSampleCountPercentile":""}}', 'MessageAttributes': {}, 'Type': 'Notification', 'UnsubscribeUrl': 'https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:448472785679:PA-Failure:02a48004-6777-4712-8df5-f6ed3ab3908c', 'TopicArn': 'arn:aws:sns:us-east-1:448472785679:PA-Failure', 'Subject': 'ALARM: "pa-status-failed" in US East (N. Virginia)'}}]}

i = 1

def parse_dict(the_dict, prefix=''):
    print()
    i = 1
    # kw = max([len(key) for key in the_dict.keys()])
    for k, v in the_dict.iteritems():
        v_type = type(v)
        print('{prefix}dict({i}): KEY: {k:20} VAL ({v_type}): {v}'.format(**locals()))
        if type(v) is list:
            prefix += '  '
            parse_list(v, prefix)
        elif type(v) is dict:
            prefix += '  '
            parse_dict(v, prefix)
        i += 1


def parse_list(the_list, prefix=''):
    print()
    i = 1
    for v in the_list:
        v_type = type(v)
        print('{prefix}list({i}): VAL ({v_type}): {v}'.format(**locals()))
        if type(v) is list:
            prefix += '  '
            parse_list(v, prefix)
        elif type(v) is dict:
            prefix += '  '
            parse_dict(v, prefix)

var = event
if type(var) is list:
    parse_list(var)
elif type(var) is dict:
    parse_dict(var)


message = event['Records'][0]['Sns']['Message']
print('---------------------------')
print('MESSAGE')
print('---------------------------')
print(message)
print(type(message))
# message_d = ast.literal_eval(message)
message_d = json.loads(message)
var = message_d
if type(var) is list:
    parse_list(var)
elif type(var) is dict:
    parse_dict(var)
