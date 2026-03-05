# Raspberry Pi Image Description Provisioning Map

- [1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0`](#oneOf_i0)
  - [1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > entry](#oneOf_i0_items)
    - [1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > attributesEntry`](#oneOf_i0_items_oneOf_i0)
      - [1.1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 0 > attributes`](#oneOf_i0_items_oneOf_i0_attributes)
        - [1.1.1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 0 > attributes > PMAPversion`](#oneOf_i0_items_oneOf_i0_attributes_PMAPversion)
        - [1.1.1.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 0 > attributes > system_type`](#oneOf_i0_items_oneOf_i0_attributes_system_type)
    - [1.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > partitionsEntry`](#oneOf_i0_items_oneOf_i1)
      - [1.1.2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions`](#oneOf_i0_items_oneOf_i1_partitions)
        - [1.1.2.1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitionRef](#oneOf_i0_items_oneOf_i1_partitions_items)
          - [1.1.2.1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > image`](#oneOf_i0_items_oneOf_i1_partitions_items_image)
          - [1.1.2.1.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > comment`](#oneOf_i0_items_oneOf_i1_partitions_items_comment)
          - [1.1.2.1.1.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static`](#oneOf_i0_items_oneOf_i1_partitions_items_static)
            - [1.1.2.1.1.3.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > id`](#oneOf_i0_items_oneOf_i1_partitions_items_static_id)
            - [1.1.2.1.1.3.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > uuid`](#oneOf_i0_items_oneOf_i1_partitions_items_static_uuid)
              - [1.1.2.1.1.3.2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > uuid > anyOf > item 0`](#oneOf_i0_items_oneOf_i1_partitions_items_static_uuid_anyOf_i0)
              - [1.1.2.1.1.3.2.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > uuid > anyOf > item 1`](#oneOf_i0_items_oneOf_i1_partitions_items_static_uuid_anyOf_i1)
            - [1.1.2.1.1.3.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > role`](#oneOf_i0_items_oneOf_i1_partitions_items_static_role)
          - [1.1.2.1.1.4. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > expand-to-fit`](#oneOf_i0_items_oneOf_i1_partitions_items_expand-to-fit)
    - [1.1.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > slotsEntry`](#oneOf_i0_items_oneOf_i2)
      - [1.1.3.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots`](#oneOf_i0_items_oneOf_i2_slots)
        - [1.1.3.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A`](#oneOf_i0_items_oneOf_i2_slots_A)
          - [1.1.3.1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > partitions`](#oneOf_i0_items_oneOf_i2_slots_A_partitions)
            - [1.1.3.1.1.1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > partitions > partitionRef](#oneOf_i0_items_oneOf_i2_slots_A_partitions_items)
          - [1.1.3.1.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted)
            - [1.1.3.1.1.2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2)
              - [1.1.3.1.1.2.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > key_size`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_key_size)
              - [1.1.3.1.1.2.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > cipher`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_cipher)
              - [1.1.3.1.1.2.1.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > hash`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_hash)
              - [1.1.3.1.1.2.1.4. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > label`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_label)
              - [1.1.3.1.1.2.1.5. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > uuid`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_uuid)
              - [1.1.3.1.1.2.1.6. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > mname`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_mname)
              - [1.1.3.1.1.2.1.7. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > etype`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_etype)
            - [1.1.3.1.1.2.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > partitions`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_partitions)
              - [1.1.3.1.1.2.2.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > partitions > partitionRef](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_partitions_items)
            - [1.1.3.1.1.2.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > expand-to-fit`](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_expand-to-fit)
        - [1.1.3.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > B`](#oneOf_i0_items_oneOf_i2_slots_B)
          - [1.1.3.1.2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > B > partitions`](#oneOf_i0_items_oneOf_i2_slots_B_partitions)
            - [1.1.3.1.2.1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > B > partitions > partitionRef](#oneOf_i0_items_oneOf_i2_slots_B_partitions_items)
          - [1.1.3.1.2.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > B > encrypted`](#oneOf_i0_items_oneOf_i2_slots_B_encrypted)
    - [1.1.4. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > encryptedEntry`](#oneOf_i0_items_oneOf_i3)
      - [1.1.4.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted`](#oneOf_i0_items_oneOf_i3_encrypted)
        - [1.1.4.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > anyOf > item 0`](#oneOf_i0_items_oneOf_i3_encrypted_anyOf_i0)
          - [1.1.4.1.1.1. The following properties are required](#autogenerated_heading_2)
        - [1.1.4.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > anyOf > item 1`](#oneOf_i0_items_oneOf_i3_encrypted_anyOf_i1)
          - [1.1.4.1.2.1. The following properties are required](#autogenerated_heading_3)
        - [1.1.4.1.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > luks2`](#oneOf_i0_items_oneOf_i3_encrypted_luks2)
        - [1.1.4.1.4. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > slots`](#oneOf_i0_items_oneOf_i3_encrypted_slots)
        - [1.1.4.1.5. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > partitions`](#oneOf_i0_items_oneOf_i3_encrypted_partitions)
          - [1.1.4.1.5.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > partitions > partitionRef](#oneOf_i0_items_oneOf_i3_encrypted_partitions_items)
        - [1.1.4.1.6. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > expand-to-fit`](#oneOf_i0_items_oneOf_i3_encrypted_expand-to-fit)
- [2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 1`](#oneOf_i1)
  - [2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 1 > layout`](#oneOf_i1_layout)
    - [2.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 1 > layout > provisionmap`](#oneOf_i1_layout_provisionmap)
      - [2.1.1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 1 > layout > provisionmap > entry](#oneOf_i1_layout_provisionmap_items)

**Title:** Raspberry Pi Image Description Provisioning Map

|                           |                  |
| ------------------------- | ---------------- |
| **Type**                  | `combining`      |
| **Required**              | No               |
| **Additional properties** | Any type allowed |

**Description:** The Provisioning Map (PMAP) defines how a Raspberry Pi image is provisioned on-device. It is an ordered sequence of entries describing partition assignments, slot mappings for A/B layouts, and optional LUKS2 encryption configuration. The PMAP is authored per-image and embedded in the IDP document by rpi-image-gen, or supplied manually for images built outside rpi-image-gen.

| One of(Option)      |
| ------------------- |
| [item 0](#oneOf_i0) |
| [item 1](#oneOf_i1) |

## <a name="oneOf_i0"></a>1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0`

|              |         |
| ------------ | ------- |
| **Type**     | `array` |
| **Required** | No      |

**Description:** A standalone PMAP document as a bare array of entries.

|                      | Array restrictions |
| -------------------- | ------------------ |
| **Min items**        | N/A                |
| **Max items**        | N/A                |
| **Items unicity**    | False              |
| **Additional items** | False              |
| **Tuple validation** | See below          |

| Each item of this array must be | Description          |
| ------------------------------- | -------------------- |
| [entry](#oneOf_i0_items)        | A single PMAP entry. |

### <a name="oneOf_i0_items"></a>1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > entry

|                           |                  |
| ------------------------- | ---------------- |
| **Type**                  | `combining`      |
| **Required**              | No               |
| **Additional properties** | Any type allowed |
| **Defined in**            | #/$defs/entry    |

**Description:** A single PMAP entry.

| One of(Option)                              |
| ------------------------------------------- |
| [attributesEntry](#oneOf_i0_items_oneOf_i0) |
| [partitionsEntry](#oneOf_i0_items_oneOf_i1) |
| [slotsEntry](#oneOf_i0_items_oneOf_i2)      |
| [encryptedEntry](#oneOf_i0_items_oneOf_i3)  |

#### <a name="oneOf_i0_items_oneOf_i0"></a>1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > attributesEntry`

|                           |                         |
| ------------------------- | ----------------------- |
| **Type**                  | `object`                |
| **Required**              | No                      |
| **Additional properties** | Not allowed             |
| **Defined in**            | #/$defs/attributesEntry |

**Description:** A PMAP entry that declares top-level attributes for the provisioning map, including format version and system type.

| Property                                             | Pattern | Type   | Deprecated | Definition | Title/Description                                              |
| ---------------------------------------------------- | ------- | ------ | ---------- | ---------- | -------------------------------------------------------------- |
| + [attributes](#oneOf_i0_items_oneOf_i0_attributes ) | No      | object | No         | -          | The attributes object containing PMAP version and system type. |

##### <a name="oneOf_i0_items_oneOf_i0_attributes"></a>1.1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 0 > attributes`

|                           |             |
| ------------------------- | ----------- |
| **Type**                  | `object`    |
| **Required**              | Yes         |
| **Additional properties** | Not allowed |

**Description:** The attributes object containing PMAP version and system type.

| Property                                                          | Pattern | Type             | Deprecated | Definition | Title/Description                                                                                         |
| ----------------------------------------------------------------- | ------- | ---------------- | ---------- | ---------- | --------------------------------------------------------------------------------------------------------- |
| + [PMAPversion](#oneOf_i0_items_oneOf_i0_attributes_PMAPversion ) | No      | string           | No         | -          | The PMAP format version in semver format. Used by provisioning tools to determine how to parse this PMAP. |
| + [system_type](#oneOf_i0_items_oneOf_i0_attributes_system_type ) | No      | enum (of string) | No         | -          | The partition layout type. 'flat' for a simple single-slot layout, 'slotted' for an A/B layout.           |

###### <a name="oneOf_i0_items_oneOf_i0_attributes_PMAPversion"></a>1.1.1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 0 > attributes > PMAPversion`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | Yes      |

**Description:** The PMAP format version in semver format. Used by provisioning tools to determine how to parse this PMAP.

| Restrictions                      |                                                                                                                       |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Must match regular expression** | ```^[0-9]+\.[0-9]+\.[0-9]+$``` [Test](https://regex101.com/?regex=%5E%5B0-9%5D%2B%5C.%5B0-9%5D%2B%5C.%5B0-9%5D%2B%24) |

###### <a name="oneOf_i0_items_oneOf_i0_attributes_system_type"></a>1.1.1.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 0 > attributes > system_type`

|              |                    |
| ------------ | ------------------ |
| **Type**     | `enum (of string)` |
| **Required** | Yes                |

**Description:** The partition layout type. 'flat' for a simple single-slot layout, 'slotted' for an A/B layout.

Must be one of:
* "flat"
* "slotted"

#### <a name="oneOf_i0_items_oneOf_i1"></a>1.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > partitionsEntry`

|                           |                         |
| ------------------------- | ----------------------- |
| **Type**                  | `object`                |
| **Required**              | No                      |
| **Additional properties** | Not allowed             |
| **Defined in**            | #/$defs/partitionsEntry |

**Description:** A PMAP entry that defines a flat list of partition references.

| Property                                             | Pattern | Type  | Deprecated | Definition | Title/Description                                |
| ---------------------------------------------------- | ------- | ----- | ---------- | ---------- | ------------------------------------------------ |
| + [partitions](#oneOf_i0_items_oneOf_i1_partitions ) | No      | array | No         | -          | The list of partition references for this entry. |

##### <a name="oneOf_i0_items_oneOf_i1_partitions"></a>1.1.2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions`

|              |         |
| ------------ | ------- |
| **Type**     | `array` |
| **Required** | Yes     |

**Description:** The list of partition references for this entry.

|                      | Array restrictions |
| -------------------- | ------------------ |
| **Min items**        | N/A                |
| **Max items**        | N/A                |
| **Items unicity**    | False              |
| **Additional items** | False              |
| **Tuple validation** | See below          |

| Each item of this array must be                           | Description                                                         |
| --------------------------------------------------------- | ------------------------------------------------------------------- |
| [partitionRef](#oneOf_i0_items_oneOf_i1_partitions_items) | A reference to a partition image by name, with optional attributes. |

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items"></a>1.1.2.1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitionRef

|                           |                      |
| ------------------------- | -------------------- |
| **Type**                  | `object`             |
| **Required**              | No                   |
| **Additional properties** | Not allowed          |
| **Defined in**            | #/$defs/partitionRef |

**Description:** A reference to a partition image by name, with optional attributes.

| Property                                                                    | Pattern | Type    | Deprecated | Definition | Title/Description                                                                                 |
| --------------------------------------------------------------------------- | ------- | ------- | ---------- | ---------- | ------------------------------------------------------------------------------------------------- |
| + [image](#oneOf_i0_items_oneOf_i1_partitions_items_image )                 | No      | string  | No         | -          | The name of the partition image as defined in the IDP partitionimages map.                        |
| - [comment](#oneOf_i0_items_oneOf_i1_partitions_items_comment )             | No      | string  | No         | -          | An optional human-readable comment describing this partition reference.                           |
| - [static](#oneOf_i0_items_oneOf_i1_partitions_items_static )               | No      | object  | No         | -          | Optional static attributes to fix partition properties such as UUID or role at provisioning time. |
| - [expand-to-fit](#oneOf_i0_items_oneOf_i1_partitions_items_expand-to-fit ) | No      | boolean | No         | -          | If true, the partition is expanded to fill the remaining available space on the device.           |

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_image"></a>1.1.2.1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > image`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | Yes      |

**Description:** The name of the partition image as defined in the IDP partitionimages map.

| Restrictions   |   |
| -------------- | - |
| **Min length** | 1 |

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_comment"></a>1.1.2.1.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > comment`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | No       |

**Description:** An optional human-readable comment describing this partition reference.

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_static"></a>1.1.2.1.1.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static`

|                           |             |
| ------------------------- | ----------- |
| **Type**                  | `object`    |
| **Required**              | No          |
| **Additional properties** | Not allowed |

**Description:** Optional static attributes to fix partition properties such as UUID or role at provisioning time.

| Property                                                         | Pattern | Type             | Deprecated | Definition | Title/Description                                                                                                                                                                                                                                                                |
| ---------------------------------------------------------------- | ------- | ---------------- | ---------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| - [id](#oneOf_i0_items_oneOf_i1_partitions_items_static_id )     | No      | string           | No         | -          | A partition identifier string. Not currently used.                                                                                                                                                                                                                               |
| - [uuid](#oneOf_i0_items_oneOf_i1_partitions_items_static_uuid ) | No      | Combination      | No         | -          | A UUID for this partition. For standard partitions, corresponds to the UUID of the matching partition image. For on-device created partitions such as LUKS containers, this UUID is used at partition creation allowing the partition to be identified with this UUID on device. |
| - [role](#oneOf_i0_items_oneOf_i1_partitions_items_static_role ) | No      | enum (of string) | No         | -          | The role of this partition on the device, used by the provisioning tool to apply role-specific handling.                                                                                                                                                                         |

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_static_id"></a>1.1.2.1.1.3.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > id`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | No       |

**Description:** A partition identifier string. Not currently used.

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_static_uuid"></a>1.1.2.1.1.3.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > uuid`

|              |             |
| ------------ | ----------- |
| **Type**     | `combining` |
| **Required** | No          |

**Description:** A UUID for this partition. For standard partitions, corresponds to the UUID of the matching partition image. For on-device created partitions such as LUKS containers, this UUID is used at partition creation allowing the partition to be identified with this UUID on device.

| Any of(Option)                                                           |
| ------------------------------------------------------------------------ |
| [item 0](#oneOf_i0_items_oneOf_i1_partitions_items_static_uuid_anyOf_i0) |
| [item 1](#oneOf_i0_items_oneOf_i1_partitions_items_static_uuid_anyOf_i1) |

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_static_uuid_anyOf_i0"></a>1.1.2.1.1.3.2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > uuid > anyOf > item 0`

|                           |                  |
| ------------------------- | ---------------- |
| **Type**                  | `object`         |
| **Required**              | No               |
| **Additional properties** | Any type allowed |

| Restrictions                      |                                                                                                                                                                                         |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Must match regular expression** | ```^[0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$``` [Test](https://regex101.com/?regex=%5E%5B0-9A-Fa-f%5D%7B8%7D%28-%5B0-9A-Fa-f%5D%7B4%7D%29%7B3%7D-%5B0-9A-Fa-f%5D%7B12%7D%24) |

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_static_uuid_anyOf_i1"></a>1.1.2.1.1.3.2.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > uuid > anyOf > item 1`

|                           |                  |
| ------------------------- | ---------------- |
| **Type**                  | `object`         |
| **Required**              | No               |
| **Additional properties** | Any type allowed |

| Restrictions                      |                                                                                                                               |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Must match regular expression** | ```^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$``` [Test](https://regex101.com/?regex=%5E%5B0-9A-Fa-f%5D%7B4%7D-%5B0-9A-Fa-f%5D%7B4%7D%24) |

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_static_role"></a>1.1.2.1.1.3.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > static > role`

|              |                    |
| ------------ | ------------------ |
| **Type**     | `enum (of string)` |
| **Required** | No                 |

**Description:** The role of this partition on the device, used by the provisioning tool to apply role-specific handling.

Must be one of:
* "boot"
* "system"

###### <a name="oneOf_i0_items_oneOf_i1_partitions_items_expand-to-fit"></a>1.1.2.1.1.4. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 1 > partitions > partitions items > expand-to-fit`

|              |           |
| ------------ | --------- |
| **Type**     | `boolean` |
| **Required** | No        |
| **Default**  | `false`   |

**Description:** If true, the partition is expanded to fill the remaining available space on the device.

#### <a name="oneOf_i0_items_oneOf_i2"></a>1.1.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > slotsEntry`

|                           |                    |
| ------------------------- | ------------------ |
| **Type**                  | `object`           |
| **Required**              | No                 |
| **Additional properties** | Not allowed        |
| **Defined in**            | #/$defs/slotsEntry |

**Description:** A PMAP entry that defines a map for a slotted partition layout.

| Property                                   | Pattern | Type   | Deprecated | Definition         | Title/Description            |
| ------------------------------------------ | ------- | ------ | ---------- | ------------------ | ---------------------------- |
| + [slots](#oneOf_i0_items_oneOf_i2_slots ) | No      | object | No         | In #/$defs/slotMap | The slot map for this entry. |

##### <a name="oneOf_i0_items_oneOf_i2_slots"></a>1.1.3.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots`

|                           |                 |
| ------------------------- | --------------- |
| **Type**                  | `object`        |
| **Required**              | Yes             |
| **Additional properties** | Not allowed     |
| **Defined in**            | #/$defs/slotMap |

**Description:** The slot map for this entry.

| Property                                 | Pattern | Type   | Deprecated | Definition | Title/Description                                                                  |
| ---------------------------------------- | ------- | ------ | ---------- | ---------- | ---------------------------------------------------------------------------------- |
| - [A](#oneOf_i0_items_oneOf_i2_slots_A ) | No      | object | No         | -          | The A slot, containing a list of partitions and optional encryption configuration. |
| - [B](#oneOf_i0_items_oneOf_i2_slots_B ) | No      | object | No         | -          | The B slot, containing a list of partitions and optional encryption configuration. |

###### <a name="oneOf_i0_items_oneOf_i2_slots_A"></a>1.1.3.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A`

|                           |             |
| ------------------------- | ----------- |
| **Type**                  | `object`    |
| **Required**              | No          |
| **Additional properties** | Not allowed |

**Description:** The A slot, containing a list of partitions and optional encryption configuration.

| Property                                                     | Pattern | Type   | Deprecated | Definition                   | Title/Description                                       |
| ------------------------------------------------------------ | ------- | ------ | ---------- | ---------------------------- | ------------------------------------------------------- |
| - [partitions](#oneOf_i0_items_oneOf_i2_slots_A_partitions ) | No      | array  | No         | -                            | The list of partition references assigned to this slot. |
| - [encrypted](#oneOf_i0_items_oneOf_i2_slots_A_encrypted )   | No      | object | No         | In #/$defs/encryptedNodeFlat | Optional encryption configuration for this slot.        |

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_partitions"></a>1.1.3.1.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > partitions`

|              |         |
| ------------ | ------- |
| **Type**     | `array` |
| **Required** | No      |

**Description:** The list of partition references assigned to this slot.

|                      | Array restrictions |
| -------------------- | ------------------ |
| **Min items**        | N/A                |
| **Max items**        | N/A                |
| **Items unicity**    | False              |
| **Additional items** | False              |
| **Tuple validation** | See below          |

| Each item of this array must be                                   | Description                                                         |
| ----------------------------------------------------------------- | ------------------------------------------------------------------- |
| [partitionRef](#oneOf_i0_items_oneOf_i2_slots_A_partitions_items) | A reference to a partition image by name, with optional attributes. |

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_partitions_items"></a>1.1.3.1.1.1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > partitions > partitionRef

|                           |                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------- |
| **Type**                  | `object`                                                                              |
| **Required**              | No                                                                                    |
| **Additional properties** | Not allowed                                                                           |
| **Same definition as**    | [oneOf_i0_items_oneOf_i1_partitions_items](#oneOf_i0_items_oneOf_i1_partitions_items) |

**Description:** A reference to a partition image by name, with optional attributes.

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted"></a>1.1.3.1.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted`

|                           |                           |
| ------------------------- | ------------------------- |
| **Type**                  | `object`                  |
| **Required**              | No                        |
| **Additional properties** | Not allowed               |
| **Defined in**            | #/$defs/encryptedNodeFlat |

**Description:** Optional encryption configuration for this slot.

| Property                                                                     | Pattern | Type    | Deprecated | Definition       | Title/Description                                                                                 |
| ---------------------------------------------------------------------------- | ------- | ------- | ---------- | ---------------- | ------------------------------------------------------------------------------------------------- |
| + [luks2](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2 )                 | No      | object  | No         | In #/$defs/luks2 | The LUKS2 configuration for this encrypted container.                                             |
| + [partitions](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_partitions )       | No      | array   | No         | -                | A flat list of partition references within this encrypted container.                              |
| - [expand-to-fit](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_expand-to-fit ) | No      | boolean | No         | -                | If true, the encrypted container is expanded to fill the remaining available space on the device. |

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2"></a>1.1.3.1.1.2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2`

|                           |               |
| ------------------------- | ------------- |
| **Type**                  | `object`      |
| **Required**              | Yes           |
| **Additional properties** | Not allowed   |
| **Defined in**            | #/$defs/luks2 |

**Description:** The LUKS2 configuration for this encrypted container.

| Property                                                                 | Pattern | Type              | Deprecated | Definition | Title/Description                                                                                                                                   |
| ------------------------------------------------------------------------ | ------- | ----------------- | ---------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| + [key_size](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_key_size ) | No      | enum (of integer) | No         | -          | The encryption key size in bits.                                                                                                                    |
| + [cipher](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_cipher )     | No      | string            | No         | -          | The cipher and mode used for encryption, e.g. aes-xts-plain64.                                                                                      |
| + [hash](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_hash )         | No      | string            | No         | -          | The hash algorithm used for key derivation, e.g. sha256.                                                                                            |
| - [label](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_label )       | No      | string            | No         | -          | An optional human-readable label for the LUKS2 container.                                                                                           |
| + [uuid](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_uuid )         | No      | string            | No         | -          | The UUID assigned to the LUKS2 container. Required so that the container can be identified and unlocked at runtime.                                 |
| + [mname](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_mname )       | No      | string            | No         | -          | The device mapper name for the LUKS2 container, used as the mapped device name under /dev/mapper.                                                   |
| + [etype](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_etype )       | No      | enum (of string)  | No         | -          | The encrypted container type. 'raw' for a directly encrypted block device, 'partitioned' for a LUKS2 container that itself holds a partition table. |

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_key_size"></a>1.1.3.1.1.2.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > key_size`

|              |                     |
| ------------ | ------------------- |
| **Type**     | `enum (of integer)` |
| **Required** | Yes                 |

**Description:** The encryption key size in bits.

Must be one of:
* 128
* 256
* 512

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_cipher"></a>1.1.3.1.1.2.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > cipher`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | Yes      |

**Description:** The cipher and mode used for encryption, e.g. aes-xts-plain64.

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_hash"></a>1.1.3.1.1.2.1.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > hash`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | Yes      |

**Description:** The hash algorithm used for key derivation, e.g. sha256.

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_label"></a>1.1.3.1.1.2.1.4. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > label`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | No       |

**Description:** An optional human-readable label for the LUKS2 container.

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_uuid"></a>1.1.3.1.1.2.1.5. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > uuid`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | Yes      |

**Description:** The UUID assigned to the LUKS2 container. Required so that the container can be identified and unlocked at runtime.

| Restrictions                      |                                                                                                                                                                                         |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Must match regular expression** | ```^[0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$``` [Test](https://regex101.com/?regex=%5E%5B0-9A-Fa-f%5D%7B8%7D%28-%5B0-9A-Fa-f%5D%7B4%7D%29%7B3%7D-%5B0-9A-Fa-f%5D%7B12%7D%24) |

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_mname"></a>1.1.3.1.1.2.1.6. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > mname`

|              |          |
| ------------ | -------- |
| **Type**     | `string` |
| **Required** | Yes      |

**Description:** The device mapper name for the LUKS2 container, used as the mapped device name under /dev/mapper.

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2_etype"></a>1.1.3.1.1.2.1.7. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > luks2 > etype`

|              |                    |
| ------------ | ------------------ |
| **Type**     | `enum (of string)` |
| **Required** | Yes                |

**Description:** The encrypted container type. 'raw' for a directly encrypted block device, 'partitioned' for a LUKS2 container that itself holds a partition table.

Must be one of:
* "raw"
* "partitioned"

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_partitions"></a>1.1.3.1.1.2.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > partitions`

|              |         |
| ------------ | ------- |
| **Type**     | `array` |
| **Required** | Yes     |

**Description:** A flat list of partition references within this encrypted container.

|                      | Array restrictions |
| -------------------- | ------------------ |
| **Min items**        | N/A                |
| **Max items**        | N/A                |
| **Items unicity**    | False              |
| **Additional items** | False              |
| **Tuple validation** | See below          |

| Each item of this array must be                                             | Description                                                         |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [partitionRef](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_partitions_items) | A reference to a partition image by name, with optional attributes. |

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_partitions_items"></a>1.1.3.1.1.2.2.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > partitions > partitionRef

|                           |                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------- |
| **Type**                  | `object`                                                                              |
| **Required**              | No                                                                                    |
| **Additional properties** | Not allowed                                                                           |
| **Same definition as**    | [oneOf_i0_items_oneOf_i1_partitions_items](#oneOf_i0_items_oneOf_i1_partitions_items) |

**Description:** A reference to a partition image by name, with optional attributes.

###### <a name="oneOf_i0_items_oneOf_i2_slots_A_encrypted_expand-to-fit"></a>1.1.3.1.1.2.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > A > encrypted > expand-to-fit`

|              |           |
| ------------ | --------- |
| **Type**     | `boolean` |
| **Required** | No        |
| **Default**  | `false`   |

**Description:** If true, the encrypted container is expanded to fill the remaining available space on the device.

###### <a name="oneOf_i0_items_oneOf_i2_slots_B"></a>1.1.3.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > B`

|                           |             |
| ------------------------- | ----------- |
| **Type**                  | `object`    |
| **Required**              | No          |
| **Additional properties** | Not allowed |

**Description:** The B slot, containing a list of partitions and optional encryption configuration.

| Property                                                     | Pattern | Type   | Deprecated | Definition                                                       | Title/Description                                       |
| ------------------------------------------------------------ | ------- | ------ | ---------- | ---------------------------------------------------------------- | ------------------------------------------------------- |
| - [partitions](#oneOf_i0_items_oneOf_i2_slots_B_partitions ) | No      | array  | No         | -                                                                | The list of partition references assigned to this slot. |
| - [encrypted](#oneOf_i0_items_oneOf_i2_slots_B_encrypted )   | No      | object | No         | Same as [encrypted](#oneOf_i0_items_oneOf_i2_slots_A_encrypted ) | Optional encryption configuration for this slot.        |

###### <a name="oneOf_i0_items_oneOf_i2_slots_B_partitions"></a>1.1.3.1.2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > B > partitions`

|              |         |
| ------------ | ------- |
| **Type**     | `array` |
| **Required** | No      |

**Description:** The list of partition references assigned to this slot.

|                      | Array restrictions |
| -------------------- | ------------------ |
| **Min items**        | N/A                |
| **Max items**        | N/A                |
| **Items unicity**    | False              |
| **Additional items** | False              |
| **Tuple validation** | See below          |

| Each item of this array must be                                   | Description                                                         |
| ----------------------------------------------------------------- | ------------------------------------------------------------------- |
| [partitionRef](#oneOf_i0_items_oneOf_i2_slots_B_partitions_items) | A reference to a partition image by name, with optional attributes. |

###### <a name="oneOf_i0_items_oneOf_i2_slots_B_partitions_items"></a>1.1.3.1.2.1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > B > partitions > partitionRef

|                           |                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------- |
| **Type**                  | `object`                                                                              |
| **Required**              | No                                                                                    |
| **Additional properties** | Not allowed                                                                           |
| **Same definition as**    | [oneOf_i0_items_oneOf_i1_partitions_items](#oneOf_i0_items_oneOf_i1_partitions_items) |

**Description:** A reference to a partition image by name, with optional attributes.

###### <a name="oneOf_i0_items_oneOf_i2_slots_B_encrypted"></a>1.1.3.1.2.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 2 > slots > B > encrypted`

|                           |                                                         |
| ------------------------- | ------------------------------------------------------- |
| **Type**                  | `object`                                                |
| **Required**              | No                                                      |
| **Additional properties** | Not allowed                                             |
| **Same definition as**    | [encrypted](#oneOf_i0_items_oneOf_i2_slots_A_encrypted) |

**Description:** Optional encryption configuration for this slot.

#### <a name="oneOf_i0_items_oneOf_i3"></a>1.1.4. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > encryptedEntry`

|                           |                        |
| ------------------------- | ---------------------- |
| **Type**                  | `object`               |
| **Required**              | No                     |
| **Additional properties** | Not allowed            |
| **Defined in**            | #/$defs/encryptedEntry |

**Description:** A PMAP entry that defines an encrypted container.

| Property                                           | Pattern | Type   | Deprecated | Definition               | Title/Description                                     |
| -------------------------------------------------- | ------- | ------ | ---------- | ------------------------ | ----------------------------------------------------- |
| + [encrypted](#oneOf_i0_items_oneOf_i3_encrypted ) | No      | object | No         | In #/$defs/encryptedNode | The encrypted container configuration for this entry. |

##### <a name="oneOf_i0_items_oneOf_i3_encrypted"></a>1.1.4.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted`

|                           |                       |
| ------------------------- | --------------------- |
| **Type**                  | `combining`           |
| **Required**              | Yes                   |
| **Additional properties** | Not allowed           |
| **Defined in**            | #/$defs/encryptedNode |

**Description:** The encrypted container configuration for this entry.

| Property                                                             | Pattern | Type    | Deprecated | Definition                                                         | Title/Description                                                                                 |
| -------------------------------------------------------------------- | ------- | ------- | ---------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| + [luks2](#oneOf_i0_items_oneOf_i3_encrypted_luks2 )                 | No      | object  | No         | Same as [luks2](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2 ) | The LUKS2 configuration for this encrypted container.                                             |
| - [slots](#oneOf_i0_items_oneOf_i3_encrypted_slots )                 | No      | object  | No         | Same as [slots](#oneOf_i0_items_oneOf_i2_slots )                   | A slot map defining named A/B partition sets within this encrypted container.                     |
| - [partitions](#oneOf_i0_items_oneOf_i3_encrypted_partitions )       | No      | array   | No         | -                                                                  | A flat list of partition references within this encrypted container.                              |
| - [expand-to-fit](#oneOf_i0_items_oneOf_i3_encrypted_expand-to-fit ) | No      | boolean | No         | -                                                                  | If true, the encrypted container is expanded to fill the remaining available space on the device. |

| Any of(Option)                                        |
| ----------------------------------------------------- |
| [item 0](#oneOf_i0_items_oneOf_i3_encrypted_anyOf_i0) |
| [item 1](#oneOf_i0_items_oneOf_i3_encrypted_anyOf_i1) |

###### <a name="oneOf_i0_items_oneOf_i3_encrypted_anyOf_i0"></a>1.1.4.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > anyOf > item 0`

|                           |                  |
| ------------------------- | ---------------- |
| **Type**                  | `object`         |
| **Required**              | No               |
| **Additional properties** | Any type allowed |

###### <a name="autogenerated_heading_2"></a>1.1.4.1.1.1. The following properties are required
* slots

###### <a name="oneOf_i0_items_oneOf_i3_encrypted_anyOf_i1"></a>1.1.4.1.2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > anyOf > item 1`

|                           |                  |
| ------------------------- | ---------------- |
| **Type**                  | `object`         |
| **Required**              | No               |
| **Additional properties** | Any type allowed |

###### <a name="autogenerated_heading_3"></a>1.1.4.1.2.1. The following properties are required
* partitions

###### <a name="oneOf_i0_items_oneOf_i3_encrypted_luks2"></a>1.1.4.1.3. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > luks2`

|                           |                                                           |
| ------------------------- | --------------------------------------------------------- |
| **Type**                  | `object`                                                  |
| **Required**              | Yes                                                       |
| **Additional properties** | Not allowed                                               |
| **Same definition as**    | [luks2](#oneOf_i0_items_oneOf_i2_slots_A_encrypted_luks2) |

**Description:** The LUKS2 configuration for this encrypted container.

###### <a name="oneOf_i0_items_oneOf_i3_encrypted_slots"></a>1.1.4.1.4. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > slots`

|                           |                                         |
| ------------------------- | --------------------------------------- |
| **Type**                  | `object`                                |
| **Required**              | No                                      |
| **Additional properties** | Not allowed                             |
| **Same definition as**    | [slots](#oneOf_i0_items_oneOf_i2_slots) |

**Description:** A slot map defining named A/B partition sets within this encrypted container.

###### <a name="oneOf_i0_items_oneOf_i3_encrypted_partitions"></a>1.1.4.1.5. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > partitions`

|              |         |
| ------------ | ------- |
| **Type**     | `array` |
| **Required** | No      |

**Description:** A flat list of partition references within this encrypted container.

|                      | Array restrictions |
| -------------------- | ------------------ |
| **Min items**        | N/A                |
| **Max items**        | N/A                |
| **Items unicity**    | False              |
| **Additional items** | False              |
| **Tuple validation** | See below          |

| Each item of this array must be                                     | Description                                                         |
| ------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [partitionRef](#oneOf_i0_items_oneOf_i3_encrypted_partitions_items) | A reference to a partition image by name, with optional attributes. |

###### <a name="oneOf_i0_items_oneOf_i3_encrypted_partitions_items"></a>1.1.4.1.5.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > partitions > partitionRef

|                           |                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------- |
| **Type**                  | `object`                                                                              |
| **Required**              | No                                                                                    |
| **Additional properties** | Not allowed                                                                           |
| **Same definition as**    | [oneOf_i0_items_oneOf_i1_partitions_items](#oneOf_i0_items_oneOf_i1_partitions_items) |

**Description:** A reference to a partition image by name, with optional attributes.

###### <a name="oneOf_i0_items_oneOf_i3_encrypted_expand-to-fit"></a>1.1.4.1.6. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 0 > item 0 items > oneOf > item 3 > encrypted > expand-to-fit`

|              |           |
| ------------ | --------- |
| **Type**     | `boolean` |
| **Required** | No        |
| **Default**  | `false`   |

**Description:** If true, the encrypted container is expanded to fill the remaining available space on the device.

## <a name="oneOf_i1"></a>2. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 1`

|                           |                  |
| ------------------------- | ---------------- |
| **Type**                  | `object`         |
| **Required**              | No               |
| **Additional properties** | Any type allowed |

**Description:** A PMAP document embedded within an IDP layout object.

| Property                              | Pattern | Type   | Deprecated | Definition | Title/Description         |
| ------------------------------------- | ------- | ------ | ---------- | ---------- | ------------------------- |
| + [layout](#oneOf_i1_layout )         | No      | object | No         | -          | The IDP layout container. |
| - [](#oneOf_i1_additionalProperties ) | No      | object | No         | -          | -                         |

### <a name="oneOf_i1_layout"></a>2.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 1 > layout`

|                           |                  |
| ------------------------- | ---------------- |
| **Type**                  | `object`         |
| **Required**              | Yes              |
| **Additional properties** | Any type allowed |

**Description:** The IDP layout container.

| Property                                         | Pattern | Type   | Deprecated | Definition | Title/Description                                      |
| ------------------------------------------------ | ------- | ------ | ---------- | ---------- | ------------------------------------------------------ |
| + [provisionmap](#oneOf_i1_layout_provisionmap ) | No      | array  | No         | -          | The provisioning map array embedded in the IDP layout. |
| - [](#oneOf_i1_layout_additionalProperties )     | No      | object | No         | -          | -                                                      |

#### <a name="oneOf_i1_layout_provisionmap"></a>2.1.1. Property `Raspberry Pi Image Description Provisioning Map > oneOf > item 1 > layout > provisionmap`

|              |         |
| ------------ | ------- |
| **Type**     | `array` |
| **Required** | Yes     |

**Description:** The provisioning map array embedded in the IDP layout.

|                      | Array restrictions |
| -------------------- | ------------------ |
| **Min items**        | N/A                |
| **Max items**        | N/A                |
| **Items unicity**    | False              |
| **Additional items** | False              |
| **Tuple validation** | See below          |

| Each item of this array must be              | Description          |
| -------------------------------------------- | -------------------- |
| [entry](#oneOf_i1_layout_provisionmap_items) | A single PMAP entry. |

##### <a name="oneOf_i1_layout_provisionmap_items"></a>2.1.1.1. Raspberry Pi Image Description Provisioning Map > oneOf > item 1 > layout > provisionmap > entry

|                           |                                   |
| ------------------------- | --------------------------------- |
| **Type**                  | `combining`                       |
| **Required**              | No                                |
| **Additional properties** | Any type allowed                  |
| **Same definition as**    | [oneOf_i0_items](#oneOf_i0_items) |

**Description:** A single PMAP entry.

----------------------------------------------------------------------------------------------------------------------------
Generated using [json-schema-for-humans](https://github.com/coveooss/json-schema-for-humans) on 2026-03-05 at 17:39:33 +0000
