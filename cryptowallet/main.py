# this is needed for supporting Windows 10 with OpenGL < v2.0
# Example: VirtualBox w/ OpenGL v1.1
import os
import platform

if platform.system() == "Windows":
    os.environ["KIVY_GL_BACKEND"] = "angle_sdl2"

import kivy
from kivymd.app import MDApp
from kivy.lang import Builder
from kivy.uix.label import Label

# kivy.require('1.0.6') # replace with your current kivy version !


KV = """
Screen:
    Label:
        text: 'Hello world!'
    Image:
        source: 'assets/cat.jpg'
        size: self.texture_size
        size_hint: 0.5, 0.5

    MDIconButton:
        icon: "language-python"

"""


class MyApp(MDApp):
    def build(self):
        return Builder.load_string(KV)


if __name__ == "__main__":
    MyApp().run()
