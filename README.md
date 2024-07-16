# Ethereum Distribution system


## Simple implementation

These interfaces form a simple, un versioned distribution system, that focuses on resource contents (bytecode) over it's location (address). It allow to construct efficient factories for creating and managing multiple instances of the same resource.

Contents:

- **CodeIndex**: Simple contract allowing anyone to register association between a bytecode and it's location on chain
- **Distribution**: Contract that allows to instantiate from same resource (bytecode)
- **Distributor**: Contract that allows to instantiate from multiple resources (bytecodes)
- **Installer**: Contract that allows to install and manage multiple instances from multiple distributors

## End-goal

![image](https://github.com/user-attachments/assets/15f7e293-5d6d-45e6-9caa-63d8aa3f2613)
