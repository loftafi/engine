/// Describe a license that may be directly or indirectly depended
/// upon by this library.
pub const License = @This();

/// Short one or two word description.
library: []const u8,

/// Short one line copyright line.
copyright: []const u8,

/// Abbreviated string describing the license, i.e. "zlib", "bsd", etc...
contents: []const u8,

/// Full text of relevant license
license: []const u8,

pub const licenses = &[_]License{
    .{
        .library = "SDL3",
        .copyright = "Copyright (C) 1997-2026 Sam Lantinga <slouken@libsdl.org>",
        .contents = "zlib",
        .license =
        \\Copyright (C) 1997-2026 Sam Lantinga <slouken@libsdl.org>
        \\
        \\This software is provided 'as-is', without any express or implied warranty.  In no event will the authors be held liable for any damages arising from the use of this software.
        \\
        \\Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
        \\
        \\1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
        \\2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
        \\3. This notice may not be removed or altered from any source distribution.
        ,
    },
    .{
        .library = "SDL Mixer",
        .copyright = "Copyright (C) 1997-2026 Sam Lantinga <slouken@libsdl.org>",
        .contents = "zlib",
        .license =
        \\Copyright (C) 1997-2026 Sam Lantinga <slouken@libsdl.org>
        \\
        \\This software is provided 'as-is', without any express or implied warranty.  In no event will the authors be held liable for any damages arising from the use of this software.
        \\
        \\Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
        \\
        \\1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
        \\2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
        \\3. This notice may not be removed or altered from any source distribution.
        ,
    },
    .{
        .library = "ogg",
        .copyright = "Copyright (c) 2002-2020 Xiph.org Foundation",
        .contents = "BSD3",
        .license =
        \\https://gitlab.xiph.org/xiph/ogg
        \\
        \\----
        \\
        \\Copyright (c) 2002, Xiph.org Foundation
        \\
        \\Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
        \\
        \\- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
        \\
        \\- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
        \\
        \\- Neither the name of the Xiph.org Foundation nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
        \\
        \\THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        ,
    },
    .{
        .library = "vorbis",
        .copyright = "Copyright (c) 2002-2020 Xiph.org Foundation",
        .contents = "BSD3",
        .license =
        \\https://gitlab.xiph.org/xiph/vorbis
        \\
        \\-------
        \\
        \\Copyright (c) 2002-2020 Xiph.org Foundation
        \\
        \\Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
        \\
        \\- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
        \\
        \\- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
        \\
        \\- Neither the name of the Xiph.org Foundation nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
        \\
        \\THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        ,
    },
    .{
        .library = "libm",
        .copyright = "Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.",
        .contents = "",
        .license =
        \\Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
        \\
        \\Developed at SunPro, a Sun Microsystems, Inc. business. Permission to use, copy, modify, and distribute this software is freely granted, provided that this notice is preserved.
        ,
    },
    .{
        .library = "hidapi",
        .copyright = "Copyright (c) 2010, Alan Ott, Signal 11 Software",
        .contents = "BSD",
        .license =
        \\Copyright (c) 2010, Alan Ott, Signal 11 Software
        \\All rights reserved.
        \\
        \\Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
        \\
        \\* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
        \\
        \\* Neither the name of Signal 11 Software nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
        \\
        \\THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        ,
    },
    .{
        .library = "vulkan",
        .copyright = "Copyright 2015-2023 The Khronos Group Inc.",
        .contents = "MIT or Apache 2.0",
        .license =
        \\Copyright 2015-2023 The Khronos Group Inc.
        \\
        \\Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
        \\
        \\     http://www.apache.org/licenses/LICENSE-2.0
        \\
        \\Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
        ,
    },
    .{
        .library = "zeit",
        .copyright = "Copyright (c) 2024 Tim Culverhouse",
        .contents = "MIT",
        .license =
        \\Copyright (c) 2024 Tim Culverhouse
        \\
        \\Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
        \\
        \\The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
        \\
        \\THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        ,
    },
    .{
        .library = "zg",
        .copyright = "Copyright (c) 2021 Jose Colon Rodriguez",
        .contents = "MIT",
        .license =
        \\MIT License
        \\
        \\Copyright (c) 2021 Jose Colon Rodriguez
        \\Copyright (c) 2025 Sam Atman and contributors
        \\
        \\Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
        \\
        \\The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
        \\
        \\THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        ,
    },
    .{
        .library = "stb_image",
        .copyright = "Public Domain",
        .contents = "Public Domain",
        .license =
        \\stb_image - v2.28 - public domain image loader - http://nothings.org/stb  no warranty implied; use at your own risk
        \\
        \\stb_image_resize - v0.97 - public domain image resizing by Jorge L Rodriguez (@VinoBS) - 2014 http://github.com/nothings/stb
        \\
        \\stb_image_write - v1.16 - public domain - http://nothings.org/stb writes out PNG/BMP/TGA/JPEG/HDR images to C stdio - Sean Barrett 2010-2015 no warranty implied; use at your own risk
        ,
    },
    .{
        .library = "zstbi",
        .copyright = "Copyright (c) 2021 Michal Ziulek",
        .contents = "MIT",
        .license =
        \\MIT License
        \\
        \\Copyright (c) 2021 Michal Ziulek
        \\Copyright (c) 2024 zig-gamedev contributors
        \\
        \\Permission is hereby granted, free of charge, to any person obtaining a copy
        \\of this software and associated documentation files (the "Software"), to deal
        \\in the Software without restriction, including without limitation the rights
        \\to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        \\copies of the Software, and to permit persons to whom the Software is
        \\furnished to do so, subject to the following conditions:
        \\
        \\The above copyright notice and this permission notice shall be included in all
        \\copies or substantial portions of the Software.
        \\
        \\THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        \\IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        \\FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        \\AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        \\LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        \\OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        \\SOFTWARE.
        ,
    },
    .{
        .library = "andrewk/TrueType",
        .copyright = "The MIT License (Expat)",
        .contents = "MIT",
        .license =
        \\The MIT License (Expat)
        \\
        \\Copyright (c) contributors
        \\
        \\Permission is hereby granted, free of charge, to any person obtaining a copy
        \\of this software and associated documentation files (the "Software"), to deal
        \\in the Software without restriction, including without limitation the rights
        \\to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        \\copies of the Software, and to permit persons to whom the Software is
        \\furnished to do so, subject to the following conditions:
        \\
        \\The above copyright notice and this permission notice shall be included in
        \\all copies or substantial portions of the Software.
        \\
        \\THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        \\IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        \\FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        \\AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        \\LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        \\OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
        \\THE SOFTWARE.
        ,
    },
    .{
        // This font is included in the test folder and used in tests, and
        // is not normally distributed in binary form.
        .library = "Roboto font family",
        .copyright = "Copyright 2011 The Roboto Project Authors",
        .contents = "OFL 1.1",
        .license =
        \\Copyright 2011 The Roboto Project Authors (https://github.com/googlefonts/roboto-classic)
        \\
        \\This Font Software is licensed under the SIL Open Font License, Version 1.1.
        \\This license is copied below, and is also available with a FAQ at:
        \\https://openfontlicense.org
        \\
        \\-----------------------------------------------------------
        \\SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
        \\-----------------------------------------------------------
        \\
        \\PREAMBLE
        \\The goals of the Open Font License (OFL) are to stimulate worldwide
        \\development of collaborative font projects, to support the font creation
        \\efforts of academic and linguistic communities, and to provide a free and
        \\open framework in which fonts may be shared and improved in partnership
        \\with others.
        \\
        \\The OFL allows the licensed fonts to be used, studied, modified and
        \\redistributed freely as long as they are not sold by themselves. The
        \\fonts, including any derivative works, can be bundled, embedded,
        \\redistributed and/or sold with any software provided that any reserved
        \\names are not used by derivative works. The fonts and derivatives,
        \\however, cannot be released under any other type of license. The
        \\requirement for fonts to remain under this license does not apply
        \\to any document created using the fonts or their derivatives.
        \\
        \\DEFINITIONS
        \\"Font Software" refers to the set of files released by the Copyright
        \\Holder(s) under this license and clearly marked as such. This may
        \\include source files, build scripts and documentation.
        \\
        \\"Reserved Font Name" refers to any names specified as such after the
        \\copyright statement(s).
        \\
        \\"Original Version" refers to the collection of Font Software components as
        \\distributed by the Copyright Holder(s).
        \\
        \\"Modified Version" refers to any derivative made by adding to, deleting,
        \\or substituting -- in part or in whole -- any of the components of the
        \\Original Version, by changing formats or by porting the Font Software to a
        \\new environment.
        \\
        \\"Author" refers to any designer, engineer, programmer, technical
        \\writer or other person who contributed to the Font Software.
        \\
        \\PERMISSION & CONDITIONS
        \\Permission is hereby granted, free of charge, to any person obtaining
        \\a copy of the Font Software, to use, study, copy, merge, embed, modify,
        \\redistribute, and sell modified and unmodified copies of the Font
        \\Software, subject to the following conditions:
        \\
        \\1) Neither the Font Software nor any of its individual components,
        \\in Original or Modified Versions, may be sold by itself.
        \\
        \\2) Original or Modified Versions of the Font Software may be bundled,
        \\redistributed and/or sold with any software, provided that each copy
        \\contains the above copyright notice and this license. These can be
        \\included either as stand-alone text files, human-readable headers or
        \\in the appropriate machine-readable metadata fields within text or
        \\binary files as long as those fields can be easily viewed by the user.
        \\
        \\3) No Modified Version of the Font Software may use the Reserved Font
        \\Name(s) unless explicit written permission is granted by the corresponding
        \\Copyright Holder. This restriction only applies to the primary font name as
        \\presented to the users.
        \\
        \\4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
        \\Software shall not be used to promote, endorse or advertise any
        \\Modified Version, except to acknowledge the contribution(s) of the
        \\Copyright Holder(s) and the Author(s) or with their explicit written
        \\permission.
        \\
        \\5) The Font Software, modified or unmodified, in part or in whole,
        \\must be distributed entirely under this license, and must not be
        \\distributed under any other license. The requirement for fonts to
        \\remain under this license does not apply to any document created
        \\using the Font Software.
        \\
        \\TERMINATION
        \\This license becomes null and void if any of the above conditions are
        \\not met.
        \\
        \\DISCLAIMER
        \\THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
        \\EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
        \\MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
        \\OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
        \\COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
        \\INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
        \\DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
        \\FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
        \\OTHER DEALINGS IN THE FONT SOFTWARE.
        ,
    },
    .{
        .library = "zig",
        .copyright = "Copyright (c) Zig contributors",
        .contents = "MIT",
        .license =
        \\The MIT License (Expat)
        \\
        \\Copyright (c) Zig contributors
        \\
        \\Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
        \\
        \\The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
        \\
        \\THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        ,
    },
};

test "licence" {
    try std.testing.expect(licenses.len > 1);
}

pub const std = @import("std");
