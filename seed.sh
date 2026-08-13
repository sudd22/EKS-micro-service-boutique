for env in dev prod; do
  for svc in auth order product payment notification; do
    aws secretsmanager put-secret-value \
    --secret-id "microservice/${env}/${svc}/db" \
    --secret-string "{\"username\":\"${svc}_user\",\"password\":\"placeholder_password\",\"host\":\"localhost\",\"port\":5432,\"dbname\":\"microservice\"}" \
    --region eu-west-2 
  done
done
for env in dev prod; do
  aws secretsmanager put-secret-value \
  --secret-id "microservice/${env}/monitoring/postgres-exporter" \
  --secret-string "{\"username\":\"${svc}_user\",\"password\":\"placeholder_password\",\"host\":\"localhost\",\"port\":5432,\"dbname\":\"microservice\"}" \
  --region eu-west-2
done
