# HelpfulInternationalization

Here are some guidelines on how we (should) approach I18n in this project.

## Short values

Normally, you should go with this approach:

```YAML
  it:
    activerecord:
      attributes: "messaggio"
```

## Long values

For long values (or relatively short values that are nested deeply), go with following approach:


```YAML
en:
  activerecord:
    attributes:
      abuse_report:
        reasons:
          hate_speech: >-
            This item does not belong on HelpfulCrowd.


            It contains hate speech or threat of violence
            against a group or an individual
```

Let's break this down.

Between phrases `...HelpfulCrowd.` and `It contains...` there are three newlines.

Between phrases `...violence` and `against...` there is one newline.

This produces following string:

```HTML
This item does not belong on HelpfulCrowd.

It contains hate speech or threat of violence against a group or an individual
```

So, with `>-` syntax we have a way to use multilines both for formatting the output and for making our YAML file easier to read without affecting the output. This is good, use it.

If your goal cannot be reached by the above, look at other options:

- https://stackoverflow.com/a/21699210/1950438
- http://yaml-multiline.info/
