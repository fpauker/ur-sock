# ur-sock

Universal robot interface implementation in ruby. This library provides functions using different interfaces of the universal robot. Primary this was designed for the new e-series.

## Getting Started

This library uses 3 interfaces of the universal robot:

Uses the RTDE socekt of universal robots. The commands are sent using TCP socket on port 30002.

### Prerequisites & Intallation

To run the server we need the following packages:


```
#installation of the necessary packages
gem install xml-smart

#installation of the gem
gem install ur-sock
```

### Functions
```
Config            | RTDE              | Primary/secondary | Dashboard
----------------- | ----------------- | ----------------- | -----------------
get_recipe        | connect           | connect           | connect

```

### Example

Connecting to robot

```
#connecting to the RTDE interfaces on port 30002
rtde = UR::Rtde.new ('192.168.1.2').connect

#connecting to the proimary/secondary interface (psi) on port 30003
psi = UR::Transfer.new('192.168.1.2').connect

#connecting to the dashboard interface on port 29999
dash = UR::Dash.new('192.168.1.2').connect
```

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Florian Pauker** - ** -
* **Jürgen Mangler** - ** -

See also the list of [contributors](https://intra.acdp.at/gogs/fpauker/ua4ur/contributors) who participated in this project.

## License

This project is licensed under the LGPL3 License - see the [LICENSE.md](LICENSE.md) file for details
