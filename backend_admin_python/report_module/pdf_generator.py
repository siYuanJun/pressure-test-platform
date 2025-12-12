import os
import pandas as pd
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from datetime import datetime


def generate_pdf_report(csv_file_path: str, output_dir: str) -> str:
    """
    生成压测报告PDF，格式与MD报告一致
    
    参数:
        csv_file_path: 压测数据CSV文件路径
        output_dir: 报告输出目录
    
    返回:
        生成的PDF文件路径
    """
    print(f"\n=== PDF生成器被调用 ===")
    print(f"CSV文件路径: {csv_file_path}")
    print(f"输出目录: {output_dir}")
    
    # 检查CSV文件是否存在
    if not os.path.exists(csv_file_path):
        print(f"✗ CSV文件不存在: {csv_file_path}")
        raise FileNotFoundError(f"CSV文件不存在: {csv_file_path}")
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成统一的时间戳
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # 生成PDF文件名（保持与图片命名一致）
    report_title = "外网压测"
    pdf_file_name = f"{report_title}_分析报告_{timestamp}.pdf"
    pdf_file_path = os.path.join(output_dir, pdf_file_name)
    print(f"生成的PDF路径: {pdf_file_path}")
    
    try:
        # 注册中文字体
        try:
            # 尝试使用系统中已安装的TTF格式中文字体
            # 首先检查是否有可用的TTF中文字体
            ttf_fonts = []
            font_directories = [
                "/System/Library/Fonts",
                "/Library/Fonts",
                "~/Library/Fonts"
            ]
            
            for font_dir in font_directories:
                font_dir = os.path.expanduser(font_dir)
                if os.path.exists(font_dir):
                    for file in os.listdir(font_dir):
                        if file.endswith('.ttf') and ('Song' in file or 'STSong' in file or 'Hei' in file or 'SimHei' in file or 'Arial Unicode' in file):
                            ttf_fonts.append(os.path.join(font_dir, file))
            
            if ttf_fonts:
                # 使用找到的第一个TTF字体
                font_path = ttf_fonts[0]
                font_name = os.path.splitext(os.path.basename(font_path))[0]
                # 直接使用字体文件名作为字体名，不添加额外后缀
                pdfmetrics.registerFont(TTFont(font_name, font_path))
                print(f"✓ 成功注册中文字体: {font_name}")
            else:
                # 如果没有找到TTF字体，尝试使用ReportLab的CMap功能处理中文
                print("✗ 未找到TTF格式中文字体，将使用ReportLab的CMap功能处理中文")
                # 设置ReportLab使用Unicode和CMap
                from reportlab.lib.fonts import addMapping
                addMapping('Helvetica', 0, 0, 'Helvetica')
                addMapping('Helvetica', 0, 1, 'Helvetica-Bold')
                addMapping('Helvetica', 1, 0, 'Helvetica-Oblique')
                addMapping('Helvetica', 1, 1, 'Helvetica-BoldOblique')
                print("✓ 已配置ReportLab使用CMap处理中文")
        except Exception as e:
            print(f"✗ 处理中文字体时出错: {e}")
            print("将使用默认字体，可能导致中文显示异常")
        
        # 读取CSV文件数据
        print(f"开始读取CSV文件...")
        df = pd.read_csv(csv_file_path)
        print(f"CSV文件读取成功，数据行数：{len(df)}")
        print(f"数据列名：{list(df.columns)}")
        print(f"""数据内容：
{df}""")
        
        # 创建PDF文档
        doc = SimpleDocTemplate(
            pdf_file_path,
            pagesize=A4,
            rightMargin=20,
            leftMargin=20,
            topMargin=30,
            bottomMargin=20
        )
        
        story = []
        
        # 设置样式，使用中文字体
        try:
            # 检查是否有自定义注册的中文字体
            registered_fonts = pdfmetrics.getRegisteredFontNames()
            custom_font = None
            
            for font_name in registered_fonts:
                if 'STSong' in font_name or 'SimHei' in font_name or 'Song' in font_name or 'Hei' in font_name:
                    custom_font = font_name
                    break
            
            if custom_font:
                normal_font = custom_font
                bold_font = custom_font  # 使用相同字体作为粗体
                print(f"✓ 使用自定义中文字体: {custom_font}")
            else:
                # 如果没有自定义字体，但已启用CMap，直接使用默认字体
                normal_font = 'Helvetica'
                bold_font = 'Helvetica-Bold'
                print("使用默认英文字体，依赖CMap功能显示中文")
        except Exception as e:
            print(f"✗ 获取字体列表出错，使用默认字体: {e}")
            normal_font = 'Helvetica'
            bold_font = 'Helvetica-Bold'
        title_style = ParagraphStyle(
            'TitleStyle',
            fontName=bold_font,
            fontSize=18,
            spaceAfter=20,
            alignment=TA_CENTER,
            leading=22
        )
        
        subtitle_style = ParagraphStyle(
            'SubtitleStyle',
            fontName=bold_font,
            fontSize=16,
            spaceAfter=15,
            alignment=TA_LEFT,
            leading=20
        )
        
        heading2_style = ParagraphStyle(
            'Heading2Style',
            fontName=bold_font,
            fontSize=14,
            spaceAfter=12,
            alignment=TA_LEFT,
            leading=18
        )
        
        body_style = ParagraphStyle(
            'BodyStyle',
            fontName=normal_font,
            fontSize=12,
            spaceAfter=12,
            leading=16
        )
        
        italic_style = ParagraphStyle(
            'ItalicStyle',
            fontName=normal_font,
            fontSize=12,
            spaceAfter=12,
            leading=16
        )
        
        table_title_style = ParagraphStyle(
            'TableTitleStyle',
            fontName=bold_font,
            fontSize=12,
            spaceAfter=10,
            alignment=TA_LEFT,
            leading=16
        )
        
        bullet_style = ParagraphStyle(
            'BulletStyle',
            fontName=normal_font,
            fontSize=12,
            spaceAfter=8,
            leading=16,
            leftIndent=20,
            firstLineIndent=-20
        )
        
        # 添加标题
        story.append(Paragraph(report_title, title_style))
        
        # 添加报告信息
        story.append(Paragraph(f"<b>生成时间</b>：{datetime.now().strftime('%Y年%m月%d日 %A %H时%M分%S秒 CST')}", body_style))
        story.append(Paragraph(f"<b>详细错误日志说明</b>：报告末尾包含错误请求的详细分析", body_style))
        story.append(Spacer(1, 20))
        
        # 1. 测试结果概览
        story.append(Paragraph("1. 测试结果概览", heading2_style))
        
        # 测试结果表格
        # 从CSV数据中提取测试结果
        test_results_data = [
            ['测试项', '并发数', 'QPS', '平均延迟(ms)', 'Docker容器CPU峰值(%)', 'Docker容器内存峰值(MB)', '错误数', '状态码日志']
        ]
        
        for _, row in df.iterrows():
            test_results_data.append([
                row['测试项'],
                str(row['并发数']),
                str(row['QPS']),
                str(row['平均延迟(ms)']),
                str(row['Docker容器CPU峰值(%)']),
                str(row['Docker容器内存峰值(MB)']),
                str(row['错误数']),
                row['状态码日志路径']
            ])
        
        test_results_table = Table(test_results_data, colWidths=[doc.width * 0.15, doc.width * 0.1, doc.width * 0.08, doc.width * 0.12, 
                                                                doc.width * 0.15, doc.width * 0.15, doc.width * 0.08, doc.width * 0.17])
        
        test_results_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), bold_font),
            ('FONTNAME', (0, 1), (-1, -1), normal_font),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('TOPPADDING', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
            ('TOPPADDING', (0, 1), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(test_results_table)
        story.append(Spacer(1, 20))
        
        # 2. 性能分析
        story.append(Paragraph("2. 性能分析", heading2_style))
        
        # 2.1 最佳QPS
        story.append(Paragraph("2.1 最佳QPS", subtitle_style))
        
        # 找出最佳QPS（最大QPS）
        best_qps_row = df.loc[df['QPS'].idxmax()]
        best_qps_data = [
            ['测试项', '最佳QPS', '对应并发数'],
            [best_qps_row['测试项'], str(best_qps_row['QPS']), str(best_qps_row['并发数'])]
        ]
        
        best_qps_table = Table(best_qps_data, colWidths=[doc.width * 0.3, doc.width * 0.3, doc.width * 0.3])
        
        best_qps_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), bold_font),
            ('FONTNAME', (0, 1), (-1, -1), normal_font),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('TOPPADDING', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
            ('TOPPADDING', (0, 1), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(best_qps_table)
        story.append(Spacer(1, 15))
        
        # 2.2 性能拐点分析
        story.append(Paragraph("2.2 性能拐点分析", subtitle_style))
        story.append(Paragraph("性能拐点是指系统性能（QPS）开始显著下降时的并发数。", body_style))
        
        inflection_data = [
            ['测试项', '性能拐点（并发数）', '拐点处QPS'],
            [best_qps_row['测试项'], '', '']
        ]
        
        inflection_table = Table(inflection_data, colWidths=[doc.width * 0.3, doc.width * 0.3, doc.width * 0.3])
        
        inflection_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), bold_font),
            ('FONTNAME', (0, 1), (-1, -1), normal_font),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('TOPPADDING', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
            ('TOPPADDING', (0, 1), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(inflection_table)
        story.append(Spacer(1, 20))
        
        # 3. 系统资源使用分析
        story.append(Paragraph("3. 系统资源使用分析", heading2_style))
        
        # 计算平均资源使用
        avg_cpu = df['Docker容器CPU峰值(%)'].mean()
        avg_memory = df['Docker容器内存峰值(MB)'].mean()
        
        story.append(Paragraph(f"- 平均CPU使用率：{avg_cpu}%", bullet_style))
        story.append(Paragraph(f"- 平均内存使用：{avg_memory}MB", bullet_style))
        story.append(Spacer(1, 20))
        
        # 4. 错误分析
        story.append(Paragraph("4. 错误分析", heading2_style))
        total_errors = df['错误数'].sum()
        if total_errors > 0:
            story.append(Paragraph(f"- 总错误数：{total_errors}", bullet_style))
            # 添加错误详情
            for _, row in df.iterrows():
                if row['错误数'] > 0:
                    story.append(Paragraph(f"  - {row['测试项']}（并发数：{row['并发数']}）：{row['错误数']}个错误", bullet_style))
        else:
            story.append(Paragraph("- 未发现错误请求", bullet_style))
        story.append(Spacer(1, 20))
        
        # 5. 结论与建议
        story.append(Paragraph("5. 结论与建议", heading2_style))
        if total_errors > 0:
            story.append(Paragraph("- 系统存在错误请求，建议检查错误日志并优化系统", bullet_style))
        else:
            story.append(Paragraph("- 系统整体性能表现良好，未发现错误请求", bullet_style))
        story.append(Paragraph(f"- 建议根据最佳QPS对应的并发数（{best_qps_row['并发数']}）进行系统配置", bullet_style))
        
        # 生成PDF
        print("开始构建PDF文档...")
        doc.build(story)
        print("PDF文档构建成功！")
        
        # 验证PDF文件
        if os.path.exists(pdf_file_path):
            file_size = os.path.getsize(pdf_file_path)
            print(f"PDF文件已生成！")
            print(f"文件路径: {pdf_file_path}")
            print(f"文件大小: {file_size} 字节")
            return pdf_file_path
        else:
            print(f"✗ PDF文件生成失败，文件不存在")
            raise FileNotFoundError(f"PDF文件生成失败，文件不存在: {pdf_file_path}")
            
    except Exception as e:
        print(f"✗ PDF生成过程中发生异常: {e}")
        import traceback
        traceback.print_exc()
        raise
