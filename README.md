# Al Ajwad

## Development Environment
1. To run the julia cleaning code, download the [timestmaps](https://drive.google.com/drive/folders/15cu9rU46lkDog3NngJ_5LVQxxsyC6vlV?usp=sharing) and launch the devcontainer extension in VSCode. 
2. Open a new terminal and run the following commands:
```bash
julia --project=AlAjwad -E "using Pluto; Pluto.run()"
```
3. To push changes to the repository, run the following commands:
```bash
gh auth login # use https when prompted
gh auth setup-git
```