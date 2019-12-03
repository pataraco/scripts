#!/usr/bin/python

"""
Description:
    messing around with and practicing 'argparse'
"""

"""
argparse.ArgumentParser(prog=None, usage=None, description=None, epilog=None, parents=[], formatter_class=argparse.HelpFormatter, prefix_chars='-', fromfile_prefix_chars=None, argument_default=None, conflict_handler='error', add_help=True, allow_abbrev=True)

Create a new ArgumentParser object. All parameters should be passed as keyword arguments. Each parameter has its own more detailed description below, but in short they are:

  * prog : "%(prog)s" - The name of the program (default: sys.argv[0])
  * usage - The string describing the program usage
            (default: generated from arguments added to parser)
  * description - Text to display before the argument help (default: none)
  * epilog - Text to display after the argument help (default: none)
  * parents - A list of ArgumentParser objects whose arguments should also be included
  * formatter_class - A class for customizing the help output
  * prefix_chars - The set of characters that prefix optional arguments (default: ‘-‘)
  * fromfile_prefix_chars - The set of characters that prefix files from which additional arguments should be read (default: None)
  * argument_default - The global default value for arguments (default: None)
  * conflict_handler - The strategy for resolving conflicting optionals (usually unnecessary)
  * add_help - Add a -h/–help option to the parser (default: True)
  * allow_abbrev - Allows long options to be abbreviated if the abbreviation is unambiguous. (default: True)

ArgumentParser.add_argument(name or flags...[, action][, nargs][, const][, default][, type][, choices][, required][, help][, metavar][, dest])

Define how a single command-line argument should be parsed. Each parameter has its own more detailed description below, but in short they are:

  * name or flags - Either a name or a list of option strings, e.g. foo or -f, --foo.
  * action - The basic type of action to be taken when this argument is encountered at the command line.
            (store, stre_const, store_true, store_false, append, append_const, count, help, version)
  * nargs - The number of command-line arguments that should be consumed.
  * const - A constant value required by some action and nargs selections.
  * default - The value produced if the argument is absent from the command line.
  * type - The type to which the command-line argument should be converted.
  * choices - A container of the allowable values for the argument.
  * required - Whether or not the command-line option may be omitted (optionals only).
  * help - A brief description of what the argument does.
  * metavar - A name for the argument in usage messages.
  * dest - The name of the attribute to be added to the object returned by parse_args().

"""

import argparse

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('integers',
                    metavar='N',
                    type=int,
                    nargs='+',
                    help='an integer for the accumulator')
parser.add_argument('--sum',
                    dest='accumulate',
                    action='store_const',
                    const=sum,
                    default=max,
                    help='sum the integers (default: find the max)')

args = parser.parse_args()
print(args.accumulate(args.integers))

exit

"""
# nothing much really - just get defaults (-h and --help and error messages)
parser = argparse.ArgumentParser()
parser.parse_args()
"""

"""
# add positional parameters
parser = argparse.ArgumentParser()
parser.add_argument("phrase", help="echo the phrase provided")
args = parser.parse_args()
print(args.phrase)
"""

"""
# specify argument type
parser = argparse.ArgumentParser()
parser.add_argument("number", help="display a square of a given number", type=int)
args = parser.parse_args()
print(args.number**2)
"""

"""
# add optional parameters
parser = argparse.ArgumentParser()
# this requires a value by default : e.g. VERBOSITY
parser.add_argument("--verbosity", help="set output verbosity")
args = parser.parse_args()
if args.verbosity:
    print "verbosity set to " + args.verbosity
"""

"""
# add optional parameters
parser = argparse.ArgumentParser()
# action="store_true" - states to only get a true/false value
parser.add_argument("-v", help="turn on verbose output", action="store_true")
parser.add_argument("--verbose", help="turn on verbose output", action="store_true")
args = parser.parse_args()
if args.verbose:
    print "verbosity turned on with '--verbose'"
if args.v:
    print "verbosity turned on with '-v'"
"""

"""
# add optional parameters
parser = argparse.ArgumentParser()
# action="store_true" - states to only get a true/false value
parser.add_argument("-v", "--verbose", help="turn on verbose output", action="store_true")
args = parser.parse_args()
if args.verbose:
    print "verbosity turned on"
"""

"""
# combined
parser = argparse.ArgumentParser()
parser.add_argument("number", help="display a square of a given number", type=int)
parser.add_argument("-v", "--verbosity", help="turn on verbose output", action="store_true")
parser.add_argument("-f", "--format", help="set output format", type=int, choices=[1,2])
args = parser.parse_args()
square = args.number**2
if args.verbose:
    if args.format == 1:
        print("the square of {} equals {}".format(args.number, square))
    elif args.format == 2:
        print("here's the equation: {}^2 = {}".format(args.number, square))
    else:
        print("{} squared = {}".format(args.number, square))
else:
    if args.format == 1:
        print(square)
    elif args.format == 2:
        print("{}^2 = {}".format(args.number, square))
    else:
        print("{} squared = {}".format(args.number, square))
"""

"""
# combined
parser = argparse.ArgumentParser()
parser.add_argument("x", help="the base", type=int)
parser.add_argument("y", help="the exponent", type=int)
# action="count" - allows multiple v's, default sets it to 0 if not given
parser.add_argument("-v", "--verbosity", help="increase output verbosity", action="count", default=0)
args = parser.parse_args()
answer = args.x**args.y
if args.verbosity >= 2:
    print("{} to the power of {} equals {}".format(args.x, args.y, answer))
elif args.verbosity >= 1:
    print("{}^{} = {}".format(args.x, args.y, answer))
else:
    print(answer)
"""

"""
# mutually exclusive arguments
parser = argparse.ArgumentParser(description="calculate X to the power of Y")
group = parser.add_mutually_exclusive_group()
group.add_argument("-v", "--verbose", action="store_true")
group.add_argument("-q", "--quiet", action="store_true")
parser.add_argument("x", type=int, help="the base")
parser.add_argument("y", type=int, help="the exponent")
args = parser.parse_args()
answer = args.x**args.y

if args.quiet:
    print(answer)
elif args.verbose:
    print("{} to the power {} equals {}".format(args.x, args.y, answer))
else:
    print("{}^{} = {}".format(args.x, args.y, answer))
"""

