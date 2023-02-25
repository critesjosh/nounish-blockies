// process the nouns color palette

const palette = "000000c5b9a1ffffffcfc2ab63a0f9807f7ecaeff95648ed5a423fb9185ccbc1bcb87b11fffdf24b49493432351f1d29068940867c1dae32089f21a0f98f30fe500cd26451fd8b5b5a65fad22209e9265cc54e3880a72d4bea6934ac80eed81162616dff638d8bc0c5c4da53000000f3322cffae1affc110505a5cffef16fff671fff449db8323df2c39f938d85c25fb2a86fd45faff38dd56ff3a0ed32a099037076e3206552e05e8705bf38b7ce4a499667af9648df97cc4f297f2fba3efd087e4d971bde4ff1a0bf78a182b83f6d62149834398ffc925d9391fbd2d24ff7216254efbe5e5de00a556c5030eabf131fb4694e7a32cfff0ee009c590385eb00499ce1183326b1f3fff0bed8dadfd7d3cd1929f4eab1180b5027f9f5cbcfc9b8feb9d5f8d6895d606176858b757576ff0e0e0adc4dfdf8ff70e890f7913dff1ad2ff82ad535a15fa6fe2ffe939ab36beadc8cc604666f20422abaaa84b65f7a19c9a58565cda42cb027c92cec189909b0e74580d027ee6b2958defad817d635eeff2fa6f597ad4b7b2d18687cd916d6b3f394d271b85634ff9f4e6f8ddb0b92b3cd08b11257ceda3baed5fd4fbc16710a28ef43a085b67b1e31e3445ffd067962236769ca95a6b7b7e5243a86f608f785ecc059542ffb0d56333b8ced2f39713e8e8e2ec5b43235476b2a8a5d6c3be49b38bfccf25f59b34375dfc99e6de27a463554543b19e00d4a0159f4b27f9e8dd6b72129d8e6e4243f8fa5e20f82905555353876f69410d66552d1df71248fee3f3c169232b28340079fcd31e14f830018dd122fffdf4ffa21ee4afa3fbc311aa940ceedc00fff0069cb4b8a38654ae6c0a2bb26be2c8c0f89865f86100dcd8d3049d43d0aea9f39d44eeb78cf9f5e95d3500c3a199aaa6a4caa26afde7f5fdf008fdcef2f681e6018146d19a549eb5e1f5fcff3f932300fcff4a5358fbc800d596a6ffb913e9ba12767c0ef9f6d1d29607f8ce47395ed1ffc5f0d4cfc0"

const colors = palette.match(/.{1,6}/g) ?? []

colors.map((c, index) => {
    var rgb = parseInt(c, 16);   // convert rrggbb to decimal
    var r = (rgb >> 16) & 0xff;  // extract red
    var g = (rgb >>  8) & 0xff;  // extract green
    var b = (rgb >>  0) & 0xff;  // extract blue

     var luma = 0.2126 * r + 0.7152 * g + 0.0722 * b; // per ITU-R BT.709
    
    if (luma < 45) {
       console.log(c, index)
    }
})

// console.log(result)