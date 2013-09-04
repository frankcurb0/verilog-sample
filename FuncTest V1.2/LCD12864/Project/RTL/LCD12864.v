/****************************************Copyright (c)**************************************************
**                                      Dongdong   Studio 
**                                     
**---------------------------------------File Info-----------------------------------------------------
** File name:           LCD12864
** Last modified Date:  2012-6-18
** Last Version:        1.0
** Descriptions:        LCD12864
**------------------------------------------------------------------------------------------------------
** Created by:          dongdong
** Created date:        2012-6-18
** Version:             1.0
** Descriptions:        The original version
**
**------------------------------------------------------------------------------------------------------
** Modified by:			
** Modified date:		
** Version:				
** Descriptions:		
**
**------------------------------------------------------------------------------------------------------
********************************************************************************************************/
module LCD12864(
input                     sys_clk  ,                //osc clock input
input                     sys_rst_n,                //ϵͳ��λ����
output  reg               LCD_DI   ,                //LCD�ļĴ���ѡ������ź�
output                    LCD_RW   ,                //LCD�Ķ���д����ѡ������ź�
output                    LCD_EN   ,                //LCDʹ���ź�
output  reg    [7:0]      LCD_DATA ,                //LCD���������ߣ������ж���������Ϊ�����
output                    LCD_CS1  ,                // PSB, 1 is  8 bit data mode
output  reg               LCD_RST        
);           

// Prameter define

parameter IDLE                = 9'b00000000;        //��ʼ״̬����һ��״̬ΪCLEAR
parameter SETFUNCTION         = 9'b00000001;        //�������ã�8λ���ݽӿ�
parameter SETFUNCTION2        = 9'b00000010;        
parameter SWITCHMODE          = 9'b00000100;        //��ʾ���ؿ��ƣ�����ʾ��������˸�ر�
parameter CLEAR               = 9'b00001000;        //����
parameter SETMODE             = 9'b00010000;        //���뷽ʽ���ã����ݶ�д�����󣬵�ַ�Զ���һ/���治��
parameter SETDDRAM            = 9'b00100000;        //����DDRAM�ĵ�ַ����һ����ʼΪ0x80/�ڶ���Ϊ0x90
parameter WRITERAM            = 9'b01000000;        //����д��DDRAM��Ӧ�ĵ�ַ
parameter STOP                = 9'b10000000;        //LCD������ϣ��ͷ������


// REGs
reg            [23:0]     wait_cnt    ;                

reg                       sys_clk_lcd ;             //LCDʱ���ź�
reg            [23:0]     cnt         ;
reg            [8:0]      state       ;             //State Machine code

reg                       flag        ;             //��־λ��LCD�������Ϊ0
reg            [4:0]      char_cnt    ;                
reg            [7:0]      data_disp   ;

// ===================================
// ********** MAIN CODE **************
// ===================================

assign LCD_CS1 = 1; // PSB, 1 is  8 bit data mode

// wait for 40ms when power on
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        wait_cnt <= 24'b0;
    else if( wait_cnt < 24'hff_ffff)
        wait_cnt <= wait_cnt + 24'b1;
    else ;
end

// LCD RST VLD when 40ms has passed after power on
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        LCD_RST <= 1'b0;
    else if( wait_cnt == 24'hff_ffff)
        LCD_RST <= 1'b1;
    else 
        LCD_RST <= 1'b0;
end

// sys_clkƵ��Ϊ50MHz, ����LCDʱ���ź�, 10Hz
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) 
        cnt <= 24'b0;
    else if( cnt == 2499999 ) 
        cnt <= 24'b0;
    else
        cnt <= cnt + 24'b1;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) 
        sys_clk_lcd <= 0 ; 
    else if(cnt == 2499999) 
        sys_clk_lcd <= ~sys_clk_lcd ;
    else ;
end

assign LCD_RW = 1'b0;                                     //û�ж�������R/W�ź�ʼ��Ϊ�͵�ƽ
assign LCD_EN  = ( flag == 1) ? sys_clk_lcd : 1'b0;        //E�źų��ָߵ�ƽ�Լ��½��ص�ʱ����LCDʱ����ͬ

//ֻ����д���ݲ���ʱ��RS�źŲ�Ϊ�ߵ�ƽ������Ϊ�͵�ƽ
always @(posedge sys_clk_lcd or negedge sys_rst_n) begin
    if(!sys_rst_n)
        LCD_DI <= 1'b0;
    else if ( state == WRITERAM )
        LCD_DI <= 1'b1;
    else
        LCD_DI <= 1'b0;
end

// State Machine
always @(posedge sys_clk_lcd or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        state    <= IDLE;
        LCD_DATA <= 8'bzzzzzzzz;
        char_cnt <= 5'b0;
        flag     <= 1'b1;
    end
    else begin
        case(state)
        IDLE: 
        begin 
            state    <= SETFUNCTION;
            LCD_DATA <= 8'bzzzzzzzz; 
        end
        SETFUNCTION:
        begin
            state    <= SETFUNCTION2;
            LCD_DATA <= 8'h30;                // 8-bit ���ƽ��棬����ָ�����
        end
        SETFUNCTION2:
        begin
            state <= SWITCHMODE;
            LCD_DATA <= 8'h30;                            
        end
        SWITCHMODE:
        begin
            state <= CLEAR;
            LCD_DATA <= 8'h0c;                // ��ʾ���أ�����ʾ��������˸�ر�
        end
        CLEAR:
        begin
            state <= SETMODE;
            LCD_DATA <= 8'h01;               // ����    
        end
        SETMODE:
        begin
            state <= SETDDRAM;
            LCD_DATA <= 8'h06;                // ���뷽ʽ����: ���ݶ�д�󣬵�ַ�Զ���1�����治��
        end
        SETDDRAM:
        begin
            state <= WRITERAM;
            if(char_cnt == 0)                // �����ʾ���ǵ�һ���ַ��������õ�һ�е����ַ���ַ
            begin
                LCD_DATA <= 8'h80;           // Line1
            end
            else                             // �ڶ�������ʱ�������õڶ��е����ַ���ַ
            begin
                LCD_DATA <= 8'h90;           // Line2
            end
        end
        WRITERAM:
        begin
            if(char_cnt <= 11)
            begin
                char_cnt <= char_cnt + 1'b1;
                LCD_DATA <= data_disp;
                if( char_cnt == 11 )
                    state <= SETDDRAM;
                else
                    state <= WRITERAM;
            end
            else if( char_cnt >= 12 && char_cnt <= 27)
            begin
                LCD_DATA <= data_disp;
                if(char_cnt == 27)
                begin
                    state <= STOP;
                    char_cnt <= 5'b0;
                    flag <= 1'b0;
                end
                else 
                begin
                    state <= WRITERAM;
                    char_cnt <= char_cnt + 1'b1;
                end
            end
        end
        STOP: state <= STOP;
            default: state <= IDLE;
        endcase
    end
end

//������ַ�
always @(char_cnt) begin
    case (char_cnt)
        6'd0: data_disp = "H";        //        ��
        6'd1: data_disp = "e";        //        һ
        6'd2: data_disp = "l";        //        ��
        6'd3: data_disp = "l";        //        ��
        6'd4: data_disp = "o";        //        ��
        6'd5: data_disp = ",";        //        ʾ
        6'd6: data_disp = "w";        //        ��
        6'd7: data_disp = "o";        //        ��
        6'd8: data_disp = "r";        //
        6'd9: data_disp = "l";        //        �ַ���������ʽ
        6'd10: data_disp = "d";        //
        6'd11: data_disp ="!";         //                

        6'd12: data_disp = "d";        //        �ڶ��е���ʾ����
        6'd13: data_disp = "o";        //
        6'd14: data_disp = "n";
        6'd15: data_disp = "g";        
        6'd16: data_disp = "d";
        6'd17: data_disp = "o";
        6'd18: data_disp = "n";
        6'd19: data_disp = "g";
        6'd20: data_disp = "@";
        6'd21: data_disp = "s";
        6'd22: data_disp = "t";
        6'd23: data_disp = "u";
        6'd24: data_disp = "d";
        6'd25: data_disp = "i";
        6'd26: data_disp = "o";
        default :   data_disp =  8'd32;
    endcase
end

endmodule
//end of RTL code                       