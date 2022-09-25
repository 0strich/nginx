rm -rf .env;

rm -rf nginx.tmpl;

doc clean;

docker network rm webproxy;

exit 0;
