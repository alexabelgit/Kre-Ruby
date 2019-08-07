# HelpfulCrowd CSS guidelines

## Reuse

Try to write as little CSS as possible. Thing you are working on may be a perfect candidate to be built with one of our existing components (we have dropdowns, collapsible items, buttons... you name it) or styled with our utility classes like `.position__top`.

If you need to write CSS, try not to write custom CSS. We use [Wetsy](https://github.com/mizurnix/wetsy) to have placeholders like `%margin-bottom__md` that you can extend and be sure that your element will have same margin applied at the bottom as most other elements already have.

## Pseudo-classes

Wetsy is not cool with ordering, so we need to go without @extend when ordering is important. Such is the case with pseudo-classes when we want different things to happen on `:link` `:visited` `:focus` `:hover` `:active` pseudo-classes.

### Don't do this

```scss
.my-component__link {
  &:focus {
    @extend %color__red;
  }

  &:hover {
    @extend %color__green;
  }

  &:active {
    @extend %color__blue;
  }
}
```

With extends there's no sure way to say your ordering will be the same in the output CSS.

### Do this

```scss
.my-component__link {
  &:focus {
    color: $color-red;
  }

  &:hover {
    color: $color-green;
  }

  &:active {
    color: $color-blue;
  }
}
```

This will ensure your ordering `:focus` `:hover` `:active` is kept in the output CSS.

---
In this project we mostly go with the following ordering: `:link` `:visited` `:focus` `:hover` `:active` and there's a mixin named `pseudo-classify()` which puts out an extend-free rule-set for provided property.
