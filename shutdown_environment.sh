#@IgnoreInspection BashAddShebang

echo "Setting gcloud config"
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
gcloud config list

echo "Exporting MEDIA_BUCKET, APP_CREDENTIALS"
export MEDIA_BUCKET=$PROJECT_ID-media
export APP_CREDENTIALS=key.json

echo "Deleting Cloud Spanner Instance, Database, and Table"
gcloud -q spanner instances delete quiz-instance

echo "Deleting Cloud Function"
gcloud -q functions delete process-feedback --region $REGION
gcloud -q functions delete process-answer --region $REGION

echo "Deleting Cloud Pub/Sub topic"
gcloud -q pubsub topics delete feedback answers

echo "Deleting quiz-account Service Account"
gcloud -q iam service-accounts delete quiz-account@$PROJECT_ID.iam.gserviceaccount.com
rm $GOOGLE_APPLICATION_CREDENTIALS

echo "Deleting bucket: gs://$MEDIA_BUCKET"
gsutil rm -r gs://$MEDIA_BUCKET

echo "Deleting default network"
gcloud -q compute networks delete default
