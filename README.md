# ur-sock

Universal robot interface implementation in ruby. This library provides functions using different interfaces of the universal robot. Primary this was designed for the new e-series.

## Getting Started

This library uses 3 interfaces of the universal robot:
* RTDE Interface (port 30002)
* Primary/Secondary Interface (port 30003)
* Dashboard Interface (port 29999)

### Prerequisites & Intallation

To run the server we need the following packages:


```
#installation of the necessary packages
gem install xml-smart

#installation of the gem
gem install ur-sock
```

### Interfaces

#### RTDE

The Real-Time Data Exchange (RTDE) interface can be configured with an XML file.
* Output: robot-, joint-, tool- and safety status, analog and digital I/O's and general purpose output registers
* Input: digital and analog outputs and general purpose input registers

The complete documentation of all available in- and outputs can be found on:
https://www.universal-robots.com/how-tos-and-faqs/how-to/ur-how-tos/real-time-data-exchange-rtde-guide-22229/

* Loading Config file
```ruby
#Loading the config file
conf = UR::XMLConfigFile.new "test.conf.xml"

#configure output
output_names, output_types = conf.get_recipe('out')
'''

'''ruby
### Set Speed to very slow
# speed_names, speed_types = conf.get_recipe('speed')
# speed = con.send_input_setup(speed_names, speed_types)
# speed["speed_slider_mask"] = 1
# speed["speed_slider_fraction"] = 0
# con.send(speed)

#connecting to the RTDE interfaces on port 30002
rtde = UR::Rtde.new ('192.168.1.2').connect
```

### Examples

Loading Config for RTDE interface
```ruby

```
Connecting to robot

```ruby
#connecting to the proimary/secondary interface (psi) on port 30003
psi = UR::Transfer.new('192.168.1.2').connect

#connecting to the dashboard interface on port 29999
dash = UR::Dash.new('192.168.1.2').connect
```

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Florian Pauker**
* **Jürgen Mangler**

See also the list of [contributors](https://intra.acdp.at/gogs/fpauker/ua4ur/contributors) who participated in this project.

## License

This project is licensed under the LGPL3 License - see the [LICENSE.md](LICENSE.md) file for details
