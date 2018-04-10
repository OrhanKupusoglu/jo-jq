# JSON with Bash

2018-04-10

----------

[JSON](https://en.wikipedia.org/wiki/JSON) is a syntax for serializing numbers, strings, booleans, null, objects and arrays.

First proposed by [Douglas Crockford](https://en.wikipedia.org/wiki/Douglas_Crockford) in 2001 and published as [RFC 4627](https://tools.ietf.org/html/rfc4627) (ten pages only, now obsolete) in 2006, JSON is widely used as a language-independent data format.

While JSON has six data types, an important omission has been comments, Douglas Crockford himself [explains](https://plus.google.com/+DouglasCrockfordEsq/posts/RK8qyGVaGSr) his reasoning as:

>I removed comments from JSON because I saw people were using them to hold parsing directives, a practice which would have destroyed interoperability.

Any unused key can act as a *comment*, a particularly good choice is **//**. The following example is a [valid](https://jsonlint.com/) JSON:
```
{
    "//": "my comment"
}
```

&nbsp;

## jo &mdash; the JSON Output Tool

[jo](https://github.com/jpmens/jo) is a utility to generate **structured** JSON with Bash.

Generating JSON simply with **echo** is, as expected, error-prone. This is the **unstructured** way to generate JSON with Bash. In general, other than on very simple samples using simple string manipulation to generate JSON should better be avoided.

&nbsp;

### Primitives &mdash; numbers, strings, booleans, and null

Let's start with the time-honored cliche:

```
$ jo greeting='Hello World'
{"greeting":"Hello World"}
```

jo is clever with types so that you can ignore double quotes when appropriate:
```
$ TEST_PASS=89
$ TEST_TEMP=11.43
$ TEST_NOTE='mediocre'
$ TEST_STATUS=true
$ TEST_OBJECT=null

# with double quotes
$ jo pass="$TEST_PASS" temp="$TEST_TEMP" note="$TEST_NOTE" status="$TEST_STATUS" object="$TEST_OBJECT"
{"pass":89,"temp":11.43,"note":"mediocre","status":true,"object":null}

# without double quotes
$ jo pass=$TEST_PASS temp=$TEST_TEMP note=$TEST_NOTE status=$TEST_STATUS object=$TEST_OBJECT
{"pass":89,"temp":11.43,"note":"mediocre","status":true,"object":null}
```

If strings contain white spaces then double quotes are required:
```
$ TEST_NOTE='more work is required'

$ jo pass=$TEST_PASS temp=$TEST_TEMP note="$TEST_NOTE" status=$TEST_STATUS object=$TEST_OBJECT
{"pass":89,"temp":11.43,"note":"more work is required","status":true,"object":null}
```

jo can pretty-print with **-p**:
```
$ jo -p pass=$TEST_PASS temp=$TEST_TEMP note="$TEST_NOTE" status=$TEST_STATUS object=$TEST_OBJECT
{
   "pass": 89,
   "temp": 11.43,
   "note": "more work is required",
   "status": true,
   "object": null
}
```

&nbsp;

### Objects and Arrays
jo generates arrays with **-a**:
```
$ jo -a 1 2 3
[1,2,3]

$ jo -p -a 1 2 3
[
   1,
   2,
   3
]
```
An object can be created with **key=value**:
```
$ jo dtype=temperature
{"dtype":"temperature"}
```
Suffix **[]** marks an array:
```
$ jo dtype=temperature data[]=11.9 data[]=20.3 data[]=30.7
{"dtype":"temperature","data":[11.9,20.3,30.7]}
```
This usage can be cumbersome, so nested element output can be preferable:
```
$ jo dtype=temperature data=$(jo -a 11.9 20.3 30.7)
{"dtype":"temperature","data":[11.9,20.3,30.7]}
```

Objects can be nested, too:
```
$ jo dtype=wind meta=$(jo time=day height=150 speed=m/s)
{"dtype":"wind","meta":{"time":"day","height":150,"speed":"m/s"}}
```

&nbsp;

### JSON Variables

Capturing JSON into a Bash variable with [command substitution](https://www.gnu.org/software/bash/manual/html_node/Command-Substitution.html) is quite useful:
```
$ temp=$(jo dtype=temperature data=$(jo -a 11.9 20.3 30.7))
$ wind=$(jo dtype=wind meta=$(jo time=day height=150 speed=m/s))

$ echo $temp
{"dtype":"temperature","data":[11.9,20.3,30.7]}
$ echo $wind
{"dtype":"wind","meta":{"time":"day","height":150,"speed":"m/s"}}
```

&nbsp;

## jq &mdash; the JSON Query Tool

[jq](https://github.com/stedolan/jq) is an advanced JSON processor, suitable to query and output JSON data. The [jq manual](https://stedolan.github.io/jq/manual/) contains many examples.

```
$ echo '{"dtype":"wind","meta":{"time":"day","height":150,"speed":"m/s"}}' | jq ".dtype"
"wind"
```
A JSON file can be queried, too:
```
$ cat > wind.json << EOF
{"dtype":"wind","meta":{"time":"day","height":150,"speed":"m/s"}}
EOF

$ cat wind.json
{"dtype":"wind","meta":{"time":"day","height":150,"speed":"m/s"}}

$ jq ".dtype" wind.json
"wind"
$ jq ".meta" wind.json
{
  "time": "day",
  "height": 150,
  "speed": "m/s"
}
```

Keys can be obtained:
```
$ jq --sort-keys 'keys' wind.json
[
  "dtype",
  "meta"
]
```

Instead of parsing many times, a JSON file can be read and parsed at once into an array:
```
$ jq -n --slurpfile data wind.json '$data'
[
  {
    "dtype": "wind",
    "meta": {
      "time": "day",
      "height": 150,
      "speed": "m/s"
    }
  }
]

$ jq -n --slurpfile data wind.json '$data[0].meta'
{
  "time": "day",
  "height": 150,
  "speed": "m/s"
}
```

This data can be captured with command substitution:
```
$ meta=$(jq -n --slurpfile data wind.json '$data[0].meta')
$ echo $meta
{ "time": "day", "height": 150, "speed": "m/s" }
```
