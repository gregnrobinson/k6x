Place your GCP Service Account JSON Key file within this directory. K6x will detect it automatically find it and inject it into the container at runtime. No credentials are permenantly stored within the k6x image. All `.json` files are ignored by Git by default.

Either assign the `Editor` role to the Service Account or use only the required roles to satisfy the requirements for k6.