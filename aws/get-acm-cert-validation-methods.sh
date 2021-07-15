for region in us-west-1 us-west-2 ca-central-1 us-east-1 us-east-2 eu-west-1; do
   echo $region
   for arn in $(aws acm list-certificates --region $region | jq -r .CertificateSummaryList[].CertificateArn); do
      echo $arn
      aws acm describe-certificate --region $region --certificate-arn $arn | jq -r '.Certificate.DomainValidationOptions[] | .DomainName + ": " + .ValidationMethod'
      domain=$(aws acm describe-certificate --region $region --certificate-arn $arn | jq -r '.Certificate.DomainName')
      ssm_param_name="/acm/$domain/arn"
      if ssm_param_value=$(aws ssm get-parameter --region $region --name $ssm_param_name --query Parameter.Value --output text --with-decryption 2> /dev/null); then
         echo "ssm: $ssm_param_name = $ssm_param_value"
      else
         echo "ssm param does not exist: $ssm_param_name"
      fi
   done
done
