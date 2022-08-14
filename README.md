# StarkNet-Open-Oracle

Setup :  
Install Protostar. Clone the repository. Use python 3.7.

```bash
python -m venv env
source env/bin/activate
pip install -r requirements.txt
```

Testing (local contract deployment with protostar cool features)

```
protostar test tests/
```

Use `protostar test --disable-hint-validation tests/` if using hints in the main Contract. 
