#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { SampleCdkStack } from '../lib/sample-cdk-stack';

const app = new cdk.App();
new SampleCdkStack(app, 'SampleCdkStack');
