# 物理层组帧编码 *framing_encoding*

## 编码结构

![encoding_structure](encoding_structure.png)

## 顶层设计

### 模块接口

![interface](interface.png)

```vhdl
    input clk;
    input reset_n;
    input [7:0] phr_psdu_in;
    input phr_psdu_in_valid;

    output framing_encoding_out;
    output framing_encoding_out_valid;
```

### 内部结构

![structure](structure.png)

## 原理分析

### FIFO *(First In First Out)*

* 输入端口直接与外部相连，输入数据为`1 Byte @(posedge clk)`;

* 输出端口与下级模块`CRC`相连，具体输出形式依赖于`CRC`模块采用*串行输入*or*并行输入*;

* 输入输出均有`valid`使能信号;

* 若采用串行输出`1 Bit @(posedge clk)`，由于输入输出速率不匹配，故`FIFO`内部需要一定大小的存储器，防止数据阻塞丢失;

* 若`CRC`模块采用`8 Bits`并行输入，那么`FIFO`模块可以省略;

### CRC *(Cyclic Redundancy Check)*

#### 串入并出

![crc_ss](crc_ss.png)

* 输入数据从低位到高位依次从`TX_DATA`输入，当数据全部输入后，此时对应的`TX_OUT[15:0]`即`CRC`产生的16位`FCS`码;

* 记图中16个D触发器当前状态为`fcs_n[15:0]`，则`fcs_n`状态转移过程如下

```vhdl
    always @(posedge clk) begin
        fcs_n <= {fcs_n[0]^TX_DATA, fcs_n[15:12],
                  fcs_n[11]^fcs_n[0]^TX_DATA, fcs_n[10:5],
                  fcs_n[4]^fcs_n[0]^TX_DATA, fcs_n[3:1]};
    end
```

#### 并入并出



## modules

### fifo

- input: 
    + clk: 10kHz
    + reset_n
    + [7:0] fifo_input: 1 Byte data @(posedge clk)
    + fifo_input_valid: high active, data valid

- output: 
    + fifo_output: 1 bit data @(posedge clk)
    + fifo_output_valid: high active, output valid

- how it works:
    + 8 bits in and 1 bit out @(posedge clk), using memory to store input data
        + [7:0] memory [7:0]: 8 Bytes memory
        + [2:0] count: count Bytes already stored in memory
        + [2:0] col, read_row: point to bit memory ready to output
        + [2:0] write_row: point to next empty row in memory for storing input data
    + get PSDU's length info in first Byte of datastream
        + read_data_size: high active when a new datastream starts
        + [7:0] data_size: Bytes of data
        + [7:0] send_count: count Bytes already sent out, when send_count == data_size, read_data_size high active
    + framing SHR code, output SHR first, then PHR and PSDU
        + [79:0] shr: 10 Bytes SHR code
        + [6:0] shr_count: count whether SHR ends

### crc

- input:
    + clk: 10kHz
    + reset_n: asynchronous reset active low
    + tx_data: 1 bit data in
    + tx_data_valid: high active, data valid

- output:
    + tx_out: 1 bit serial output

- how it works:
    + input serial data starts with SHR code (10 Bytes)
        + [6:0] shr_count: count from 0 to 79
    + FCS of {PHR, PSDU}
        + [15:0] fcs_n: 16 dffs, tx_out = ~fcs_n, keep refreshing until tx_data_valid turns into low, then get the FCS code
    + serial output
        + [3:0] fcs_count: count from 0 to 15, to output fcs serially
        + tx_out_valid: high active when outputing fcs

```vhdl
    [7:0] data;
```
