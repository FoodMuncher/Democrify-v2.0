// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  theme: {
    colors: {
      'champagne': {
        '50': '#fdf7ef',
        '100': '#faebd7',
        '200': '#f5d6b3',
        '300': '#eeba83',
        '400': '#e69451',
        '500': '#e0782f',
        '600': '#d16025',
        '700': '#ae4920',
        '800': '#8b3c21',
        '900': '#70331e',
        '950': '#3c180e',
      },    
      'maroon': {
        '50': '#ffeeee',
        '100': '#ffdada',
        '200': '#ffbbbb',
        '300': '#ff8b8b',
        '400': '#ff4949',
        '500': '#ff1111',
        '600': '#ff0000',
        '700': '#e70000',
        '800': '#be0000',
        '900': '#800000',
        '950': '#560000',
      },    
      'fern': {
        '50': '#f0f9f0',
        '100': '#ddf0db',
        '200': '#bae1b9',
        '300': '#8bca8c',
        '400': '#6db671',
        '500': '#399041',
        '600': '#287330',
        '700': '#205c28',
        '800': '#1b4a22',
        '900': '#173d1d',
        '950': '#0c2210',
      }, 
      'spotify_black': {
        '100': '#b3b3b3',
        '200': '#535353',
        '300': '#212121',
        '400': '#121212'
      }, 
    },
    extend: {
      fontFamily: {
        'montserrat': ['Montserrat'],
        'lato': ['Lato'],
        'garamond': ['Garamond']
      },
      colors: {
        brand: "#FD4F00",
        spotify_green: "#1ed760",
        spotify_base: "#000000",
        spotify_background_black: "#121212",
        spotify_elevated_black: "#242424",
        spotify_white: "#fff",
        spotify_subdued: "#727272"
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": theme("spacing.5"),
            "height": theme("spacing.5")
          }
        }
      }, {values})
    })
  ]
}
