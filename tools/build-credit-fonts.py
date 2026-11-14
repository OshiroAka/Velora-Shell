#!/usr/bin/env python3
"""Subset local font sources for the exact supplied credit names and biography.

Development helper only. Requires libharfbuzz-subset, no Python dependencies.
Pass the original GNU FreeSerif and GoNotoKurrent Regular font files.
"""
import argparse
import ctypes as c
import ctypes.util
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
SYMBOLS = '𝕆𝕤𝕙𝕚𝕣𝕠_𝘏𝘈𝘙𝘜✩°⋆ 𝘛𝘦𝘤𝘩𝘥𝘪𝘵𝘰𝘳𝘸𝘙𝘹𝘺𝘢𝘮'
KANA = 'なかの｡|'


def rename_sfnt(blob, family):
    """Give the subset a private family so it cannot replace a desktop font."""
    count = struct.unpack_from('>H', blob, 4)[0]
    tables = {}
    for i in range(count):
        tag, _, offset, length = struct.unpack_from('>4sIII', blob, 12+16*i)
        tables[tag] = bytearray(blob[offset:offset+length])
    name = tables[b'name']
    _, records, start = struct.unpack_from('>HHH', name)
    replacements = {1: family, 2: 'Regular', 3: family+' 1.0', 4: family,
                    6: family.replace(' ', ''), 16: family, 17: 'Regular'}
    entries, storage = [], bytearray()
    for i in range(records):
        platform, encoding, language, identity, length, offset = struct.unpack_from('>HHHHHH', name, 6+12*i)
        value = bytes(name[start+offset:start+offset+length])
        if identity in replacements:
            value = replacements[identity].encode('utf-16-be' if platform in (0, 3) else 'ascii')
        entries.append(struct.pack('>HHHHHH', platform, encoding, language, identity, len(value), len(storage)))
        storage.extend(value)
    tables[b'name'] = struct.pack('>HHH', 0, records, 6+12*records)+b''.join(entries)+storage
    tables[b'head'][8:12] = b'\0'*4
    output = bytearray(blob[:12])+bytearray(count*16)
    for i, (tag, data) in enumerate(sorted(tables.items())):
        offset, length = len(output), len(data)
        padded = data+bytes((-length) % 4)
        checksum = sum(struct.unpack('>'+str(len(padded)//4)+'I', padded)) & 0xffffffff
        struct.pack_into('>4sIII', output, 12+16*i, tag, checksum, offset, length)
        if tag == b'head': head_offset = offset
        output.extend(padded)
    checksum = sum(struct.unpack('>'+str(len(output)//4)+'I', output)) & 0xffffffff
    struct.pack_into('>I', output, head_offset+8, (0xb1b0afba-checksum) & 0xffffffff)
    return output


def subset(source, characters, family, target):
    hb = c.CDLL(ctypes.util.find_library('harfbuzz'))
    sub = c.CDLL(ctypes.util.find_library('harfbuzz-subset'))
    declarations = {
        'hb_blob_create_from_file_or_fail': ([c.c_char_p], c.c_void_p),
        'hb_face_create': ([c.c_void_p, c.c_uint], c.c_void_p),
        'hb_face_reference_blob': ([c.c_void_p], c.c_void_p),
        'hb_blob_get_data': ([c.c_void_p, c.POINTER(c.c_uint)], c.c_void_p),
        'hb_set_add': ([c.c_void_p, c.c_uint], None),
    }
    for name in ('blob', 'face'):
        declarations[f'hb_{name}_destroy'] = ([c.c_void_p], None)
    for name, (args, result) in declarations.items():
        function = getattr(hb, name);function.argtypes, function.restype = args, result
    declarations = {
        'hb_subset_input_create_or_fail': ([], c.c_void_p),
        'hb_subset_input_unicode_set': ([c.c_void_p], c.c_void_p),
        'hb_subset_input_set': ([c.c_void_p, c.c_uint], c.c_void_p),
        'hb_subset_or_fail': ([c.c_void_p, c.c_void_p], c.c_void_p),
        'hb_subset_input_destroy': ([c.c_void_p], None),
    }
    for name, (args, result) in declarations.items():
        function = getattr(sub, name);function.argtypes, function.restype = args, result
    blob = hb.hb_blob_create_from_file_or_fail(str(source).encode())
    if not blob: raise RuntimeError('Unable to read '+str(source))
    face = hb.hb_face_create(blob, 0)
    settings = sub.hb_subset_input_create_or_fail()
    unicode_set = sub.hb_subset_input_unicode_set(settings)
    for character in set(characters): hb.hb_set_add(unicode_set, ord(character))
    names = sub.hb_subset_input_set(settings, 4)  # HB_SUBSET_SETS_NAME_ID
    for identity in (0, 13, 14): hb.hb_set_add(names, identity)
    output = sub.hb_subset_or_fail(face, settings)
    if not output: raise RuntimeError('Subsetting failed')
    output_blob = hb.hb_face_reference_blob(output)
    size = c.c_uint()
    data = hb.hb_blob_get_data(output_blob, c.byref(size))
    target.write_bytes(rename_sfnt(c.string_at(data, size.value), family))
    hb.hb_blob_destroy(output_blob);hb.hb_face_destroy(output)
    sub.hb_subset_input_destroy(settings);hb.hb_face_destroy(face);hb.hb_blob_destroy(blob)
    print(target.name, target.stat().st_size)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('free_serif', type=Path)
    parser.add_argument('go_noto_kurrent', type=Path)
    args = parser.parse_args()
    subset(args.free_serif, SYMBOLS, 'Velora Credits Symbols', ROOT/'assets/fonts/CreditsSymbols.otf')
    subset(args.go_noto_kurrent, KANA, 'Velora Credits Kana', ROOT/'assets/fonts/CreditsKana.ttf')
