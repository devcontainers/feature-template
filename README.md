# Dev Container Features

> This repo provides devcontainer features  


## Repo and Feature Structure

Similar to the [`devcontainers/features`](https://github.com/devcontainers/features) repo, this repository has a `src` folder.  Each Feature has its own sub-folder, containing at least a `devcontainer-feature.json` and an entrypoint script `install.sh`. 

```
├── src
│   ├── sqlfmt
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   ├── library_scripts.sh
│   │   └── README.md
...
```

## Features

* [sqlfmt](./src/sqlfmt/README.md)
