# ./scripts/scale_review_app.sh 659 down

case "$2" in
 down) v=0 ;;
 up) v=1 ;;
esac
scalingo --app demo-rdv-solidarites-pr$1 scale web:$v jobs:$v
