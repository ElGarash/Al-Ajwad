# Al Ajwad

## Development Environment
1. Download the [timestmaps](https://drive.google.com/drive/folders/15cu9rU46lkDog3NngJ_5LVQxxsyC6vlV?usp=sharing) or from [kaggle](https://www.kaggle.com/datasets/abdoeid/quran-com-signals-segment-level) tom `timestamps` dir. Your folder structure should look like this:
```
.
├── AlAjwad
├── ayah_text.csv
├── experiments
├── LICENSE
├── README.md
├── terminology.md
└── timestamps
    ├── AbdulBaset AbdulSamad_Mujawwad.json
    ├── AbdulBaset AbdulSamad_Murattal.json
    ├── Abdur-Rahman as-Sudais_Murattal.json
    ├── Abu Bakr al-Shatri_Murattal.json
    ├── Hani ar-Rifai_Murattal.json
    ├── Khalifah Al Tunaiji_Murattal.json
    ├── Mahmoud Khalil Al-Husary_Muallim.json
    ├── Mahmoud Khalil Al-Husary_Murattal.json
    ├── Mishari Rashid al-Afasy_Murattal.json
    ├── Mishari Rashid al-Afasy_Streaming.json
    ├── Mohamed Siddiq al-Minshawi_Murattal.json
    ├── quran-com_timestamps.json
    └── Saud ash-Shuraim_Murattal.json
```

2. Launch the devcontainer extension in VSCode.
3. Open a new terminal and run the following commands:
```bash
julia --project=AlAjwad -E "using Pluto; Pluto.run()"
```
4. To push changes to the repository, run the following commands:
```bash
gh auth login # use https when prompted
gh auth setup-git
```