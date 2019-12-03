#!/usr/bin/env python
"""
    Description:
        Script to test print out boto shit
"""

import boto3

# connect to the AWS IAM service
ec2_client = boto3.client('ec2')

iids = ['i-0988f10c91115339a']
describe_instances_output = (ec2_client.describe_instances(InstanceIds=iids))

describe_instances_output2 = ec2_client.describe_instances(
    Filters=[
        {'Name': 'tag:Role', 'Values':['Firewall']},
        {'Name': 'tag:Primary', 'Values':['false']}
    ])

reservations = describe_instances_output['Reservations']
reservation = reservations[0]
instances =  reservation['Instances']
instance = instances[0]
instance_description = instance
instance_id = instance_description['InstanceId']
tags = instance_description['Tags']
network_interfaces = instance_description['NetworkInterfaces']
#i = 1
#for k,v in network_interfaces[0].iteritems():
#    print('inetint[{0:2}]: KEY: {1:20} VAL: {2}'.format(i, k, v))
#    i += 1
#print
net_ints = [
    (
        'eth' + str(ni['Attachment']['DeviceIndex']),
        ni['NetworkInterfaceId'],
        [pi['PrivateIpAddress'] for pi in ni['PrivateIpAddresses']],
        ni['SubnetId'],
    ) for ni in network_interfaces
]
nis = {}
for ni, ei, pips, si in net_ints:
    nis[ni] = {'eni_id': ei, 'priv_ips': pips, 'subnet_id':si}

print('primary: {}'.format(net_ints))
print
print('primary: {}'.format(nis))
print

i = 1
for k,v in nis.iteritems():
    print('inetint[{0:2}]: KEY: {1:5} VAL: {2}'.format(i, k, v))
    j = 1
    for k,v in v.iteritems():
        print('    vals[{0:2}]: KEY: {1:10} VAL: {2}'.format(j, k, v))
        j += 1
    i += 1
print

exit('all done')

for ni in nis:
    print ni
    eni = nis[ni]['eni_id']
    nids = [eni]
    describe_network_interfaces_output = (
		ec2_client.describe_network_interfaces(
			NetworkInterfaceIds=nids))
    network_interfaces = describe_network_interfaces_output['NetworkInterfaces']
    #print network_interfaces
    #print
    #print len(network_interfaces)
    print
    i = 1
    for k,v in network_interfaces[0].iteritems():
        print('netint[{0:2}]: KEY: {1:20} VAL: {2}'.format(i, k, v))
        i += 1
    print
    for pi in network_interfaces[0]['PrivateIpAddresses']:
        i = 1
        for k,v in pi.iteritems():
            print('PrvIps[{0:2}]: KEY: {1:20} VAL: {2}'.format(i, k, v))
            i += 1
        if 'Association' in pi:
            print
            j = 1
            for k,v in pi['Association'].iteritems():
                print(' PiAssc[{0:2}]: KEY: {1:20} VAL: {2}'.format(j, k, v))
                j += 1
            print
        else:
            print('no Assocation')
        print
    i = 1
    for k,v in network_interfaces[0]['Attachment'].iteritems():
        print('Attach[{0:2}]: KEY: {1:20} VAL: {2}'.format(i, k, v))
        i += 1
    print
    if 'Association' in network_interfaces[0]:
        i = 1
        for k,v in network_interfaces[0]['Association'].iteritems():
            print('Associ[{0:2}]: KEY: {1:20} VAL: {2}'.format(i, k, v))
            i += 1
        print
    else:
        print('no Assocation')
    print('---------------------')

exit('all done')

private_ips = network_interfaces[0].get('PrivateIpAddresses')
for pip in private_ips:
    if 'Association' in pip:
        print pip['PrivateIpAddress'], pip['Association']['PublicIp'], pip['Association']['AllocationId']

replace_route_output = (
    ec2_client.replace_route(
        RouteTableId=self.id,
        DestinationCidrBlock='0.0.0.0/0',
        DryRun=dry_run,
        NetworkInterfaceId=network_interface_id))

associate_address_output = (
    ec2_client.associate_address(
        AllocationId=eip_allocation_id,
        DryRun=dry_run,
        NetworkInterfaceId=self.nat_network_interface_id,
        PrivateIpAddress=self.nat_primary_private_ip))

create_tags_output = (
    ec2_client.create_tags(
        DryRun=dry_run,
        Resources=[self.id],
        Tags=[{'Key': tag, 'Value': val}]))

describe_route_tables_output = ec2_client.describe_route_tables(
    Filters=[
        {'Name': 'tag:' + tag, 'Values':[val]}
    ])
route_tables = describe_route_tables_output.get('RouteTables')
