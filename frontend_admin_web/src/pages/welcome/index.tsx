import { Typography } from 'antd';

const Welcome = () => {
  return (
    <div>
      <Typography.Title level={3} style={{ marginBottom: 24 }}>
        欢迎使用压测平台管理后台
      </Typography.Title>
      <Typography.Paragraph>
        从左侧菜单进入：用户管理、压测申请审核、任务管理、报告管理。
      </Typography.Paragraph>
    </div>
  );
};

export default Welcome;
