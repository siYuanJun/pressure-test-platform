"""
报告生成服务层
"""
import os
import json
from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.report import Report, ReportType, ReportStatus
from app.models.task import Task, TaskStatus
from app.models.result import Result
from config.settings import settings
from report_module.image_generator import generate_report_image_wrapper
from report_module.pdf_generator import generate_pdf_report


class ReportService:
    """报告生成服务类"""
    
    @staticmethod
    def generate_reports_for_task(db: Session, task_id: int, report_types: Optional[List[ReportType]] = None) -> List[Report]:
        """
        为指定任务生成报告
        :param db: 数据库会话
        :param task_id: 任务ID
        :param report_types: 报告类型列表，为空则生成所有类型报告
        :return: 报告列表
        """
        # 调试信息：确保使用的是修改后的版本
        print("\n=== 这是修改后的ReportService.generate_reports_for_task函数 ===")
        print(f"任务ID: {task_id}")
        print(f"报告类型: {report_types}")
        
        # 1. 检查任务是否存在
        task = db.query(Task).filter(Task.id == task_id).first()
        if not task:
            raise ValueError(f"任务ID {task_id} 不存在")
        
        if task.status != TaskStatus.COMPLETED:
            raise ValueError("只能为已完成的任务生成报告")
        
        # 2. 获取任务结果
        result = db.query(Result).filter(Result.task_id == task_id).first()
        if not result:
            raise ValueError("任务结果数据不存在")
        
        # 调试信息：检查结果数据
        print(f"\n=== 调试：任务结果数据 ===")
        print(f"结果ID: {result.id}")
        print(f"原始data_file_path: {result.data_file_path}")
        print(f"data_file_path类型: {type(result.data_file_path)}")
        
        if not result.data_file_path:
            raise ValueError("任务结果数据文件路径为空")
        
        # 3. 检查是否已经生成了报告
        existing_reports = db.query(Report).filter(Report.task_id == task_id).all()
        existing_report_types = [report.report_type for report in existing_reports]
        
        # 4. 如果未指定报告类型，生成所有支持的报告类型
        if not report_types:
            report_types = [ReportType.IMAGE, ReportType.PDF]
        
        generated_reports = []
        csv_file_path = result.data_file_path
        print(f"使用的CSV文件路径: {csv_file_path}")
        print(f"CSV文件存在: {os.path.exists(csv_file_path)}")
        if os.path.exists(csv_file_path):
            print(f"CSV文件大小: {os.path.getsize(csv_file_path)} 字节")
        
        # 5. 生成指定类型的报告
        for report_type in report_types:
            if report_type not in existing_report_types:
                try:
                    if report_type == ReportType.IMAGE:
                        # 生成图片报告
                        print(f"开始生成图片报告，CSV路径：{csv_file_path}")
                        # 在UPLOAD_DIR下创建reports/images子目录
                        image_output_dir = os.path.join(settings.UPLOAD_DIR, 'reports', 'images')
                        os.makedirs(image_output_dir, exist_ok=True)
                        print(f"图片输出目录：{image_output_dir}")
                        report_file_path = generate_report_image_wrapper(
                            csv_file_path=csv_file_path,
                            output_dir=image_output_dir
                        )
                        print(f"图片报告生成完成，路径：{report_file_path}")
                        
                        # 检查文件是否存在
                        if os.path.exists(report_file_path):
                            file_size = os.path.getsize(report_file_path)
                            print(f"报告文件大小：{file_size} 字节")
                            
                            # 转换报告路径为/uploads形式
                            # 找到reports/images目录后的部分
                            if 'reports/images' in report_file_path:
                                # 获取reports/images之后的路径
                                reports_index = report_file_path.index('reports/images')
                                # 构建/uploads路径，确保有正确的斜杠分隔
                                db_file_path = '/uploads/' + report_file_path[reports_index:]
                                print(f"转换后的数据库路径：{db_file_path}")
                            else:
                                # 获取文件的绝对路径
                                file_abs_path = os.path.abspath(report_file_path)
                                upload_abs_path = os.path.abspath(settings.UPLOAD_DIR)
                                # 计算相对路径
                                if file_abs_path.startswith(upload_abs_path):
                                    relative_path = file_abs_path[len(upload_abs_path):]
                                    # 构建/uploads路径，确保有正确的斜杠分隔
                                    db_file_path = f'/uploads/images/{relative_path.lstrip("/")}'
                                else:
                                    # 无法转换，使用原始路径
                                    db_file_path = report_file_path
                                print(f"构建的数据库路径：{db_file_path}")
                            
                            report = Report(
                                task_id=task_id,
                                apply_id=task.apply_id,
                                report_type=report_type,
                                file_path=db_file_path,
                                file_size=file_size,
                                status=ReportStatus.COMPLETED,
                                generated_at=datetime.utcnow()
                            )
                            db.add(report)
                            generated_reports.append(report)
                            print(f"报告已添加到数据库：{report.id}")
                        else:
                            print(f"报告文件不存在，无法添加到数据库")
                    elif report_type == ReportType.PDF:
                        # 生成PDF报告
                        print(f"\n=== 开始生成PDF报告 ===")
                        print(f"CSV路径：{csv_file_path}")
                        # 在UPLOAD_DIR下创建reports/pdfs子目录
                        pdf_output_dir = os.path.join(settings.UPLOAD_DIR, 'reports', 'pdfs')
                        os.makedirs(pdf_output_dir, exist_ok=True)
                        print(f"PDF输出目录：{pdf_output_dir}")
                        print(f"输出目录是否存在：{os.path.exists(pdf_output_dir)}")
                        
                        try:
                            print(f"准备调用generate_pdf_report函数...")
                            # 导入模块，确保能找到函数
                            from report_module.pdf_generator import generate_pdf_report
                            print(f"成功导入generate_pdf_report函数")
                            
                            report_file_path = generate_pdf_report(
                                csv_file_path=csv_file_path,
                                output_dir=pdf_output_dir
                            )
                            print(f"PDF报告生成完成，返回路径：{report_file_path}")
                            print(f"返回的report_file_path类型：{type(report_file_path)}")
                            print(f"返回的report_file_path值：{report_file_path}")
                        except Exception as pdf_e:
                            print(f"generate_pdf_report函数调用失败：{pdf_e}")
                            import traceback
                            traceback.print_exc()
                            raise
                        
                        # 检查文件是否存在
                        if os.path.exists(report_file_path):
                            file_size = os.path.getsize(report_file_path)
                            print(f"报告文件大小：{file_size} 字节")
                            
                            # 转换报告路径为/uploads形式
                            # 找到reports/pdfs目录后的部分
                            if 'reports/pdfs' in report_file_path:
                                # 获取reports/pdfs之后的路径
                                reports_index = report_file_path.index('reports/pdfs')
                                # 构建/uploads路径，确保斜杠分隔正确
                                db_file_path = '/uploads/' + report_file_path[reports_index:]
                                print(f"转换后的数据库路径：{db_file_path}")
                            else:
                                # 获取文件的绝对路径
                                file_abs_path = os.path.abspath(report_file_path)
                                upload_abs_path = os.path.abspath(settings.UPLOAD_DIR)
                                # 计算相对路径
                                if file_abs_path.startswith(upload_abs_path):
                                    relative_path = file_abs_path[len(upload_abs_path):]
                                    # 构建/uploads路径
                                    db_file_path = f'/uploads{relative_path}'
                                else:
                                    # 无法转换，使用原始路径
                                    db_file_path = report_file_path
                                print(f"构建的数据库路径：{db_file_path}")
                            
                            report = Report(
                                task_id=task_id,
                                apply_id=task.apply_id,
                                report_type=report_type,
                                file_path=db_file_path,
                                file_size=file_size,
                                status=ReportStatus.COMPLETED,
                                generated_at=datetime.utcnow()
                            )
                            db.add(report)
                            generated_reports.append(report)
                            print(f"报告已添加到数据库：{report.id}")
                        else:
                            print(f"报告文件不存在，无法添加到数据库")
                    else:
                        # 其他报告类型暂不支持
                        continue
                except Exception as e:
                    # 记录错误但不中断
                    print(f"\n=== 生成{report_type}报告时发生异常 ===")
                    print(f"异常类型: {type(e).__name__}")
                    print(f"异常消息: {e}")
                    print(f"异常发生位置: {e.__traceback__.tb_frame.f_code.co_filename}:{e.__traceback__.tb_lineno}")
                    import traceback
                    traceback.print_exc()
                    report = Report(
                        task_id=task_id,
                        apply_id=task.apply_id,
                        report_type=report_type,
                        file_path="",
                        status=ReportStatus.FAILED
                    )
                    db.add(report)
        
        db.commit()
        
        # 返回所有报告，包括已存在的和新生成的
        return existing_reports + generated_reports
    
    @staticmethod
    def get_reports_by_task(db: Session, task_id: int) -> List[Report]:
        """获取任务的所有报告"""
        return db.query(Report).filter(Report.task_id == task_id).all()
    
    @staticmethod
    def get_reports_by_apply(db: Session, apply_id: int) -> List[Report]:
        """获取申请的所有报告"""
        return db.query(Report).filter(Report.apply_id == apply_id).all()
    
    @staticmethod
    def get_report_by_id(db: Session, report_id: int) -> Optional[Report]:
        """根据ID获取报告"""
        return db.query(Report).filter(Report.id == report_id).first()
    
    @staticmethod
    def _convert_upload_path_to_actual_path(upload_path: str) -> str:
        """
        将数据库中存储的/uploads格式路径转换为实际文件系统路径
        :param upload_path: 数据库中存储的/uploads格式路径
        :return: 实际文件系统路径
        """
        if upload_path.startswith('/uploads/'):
            # 获取uploads后面的路径部分
            relative_path = upload_path[9:]  # 去掉'/uploads/'前缀
            # 从UPLOAD_DIR构建实际路径
            actual_path = os.path.join(settings.UPLOAD_DIR, relative_path)
            return actual_path
        return upload_path

    @staticmethod
    def delete_report(db: Session, report_id: int):
        """删除报告（同时删除文件）"""
        report = db.query(Report).filter(Report.id == report_id).first()
        if not report:
            raise ValueError("报告不存在")
        
        # 删除文件
        actual_file_path = ReportService._convert_upload_path_to_actual_path(report.file_path)
        if os.path.exists(actual_file_path):
            try:
                os.remove(actual_file_path)
                print(f"成功删除报告文件：{actual_file_path}")
            except Exception as e:
                print(f"删除报告文件失败：{actual_file_path}，错误：{e}")
                pass  # 忽略文件删除错误
        else:
            print(f"报告文件不存在：{actual_file_path}")
        
        # 删除数据库记录
        db.delete(report)
        db.commit()

