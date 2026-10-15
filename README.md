# pelican-eggs

A collection of eggs for Pelican.

The goal of these eggs is to provide a simple and easy way to install and manage game servers on Pelican.

## Contributing

### Requirements

Any eggs submitted to this repository must meet the following criteria:

* Must have the source code of their install script available.
* Must be installable outside of the Pelican environment (ie. on a local machine).
    * Use environment variables with sane defaults to support installing on a local machine and in Pelican.
* Must contain a README with the following information:
    * Server Environment (ie. Windows, Linux, Wine, Proton, etc.)
    * Server Ports (Primary and Additional Optional or Required)
    * Server Startup Command
