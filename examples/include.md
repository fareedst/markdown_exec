This document demonstrates blocks requiring other blocks.

Block "(Winter)" is hidden.
```bash :(Winter)
echo It is now Winter
```

Block "Spring" is visible. It requires "(Winter)".
```bash :Spring +(Winter)
echo It is now Spring
```

Block "(Summer)" is hidden. It requires "(Winter)" and "Spring"
```bash :(Summer) +Spring +(Winter)
echo It is now Summer
```

Block "Fall" is visible. It requires "(Summer)" which itself requires the rest.
```bash :Fall +(Summer)
echo It is now Fall
```

Block "Sunsear" is visible. It requires "Frostfall" which does not exist and triggers an unmet dependency error.
```bash :Sunsear +Frostfall
```
