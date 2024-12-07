## DOCS:

https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
## VPC:

在AWS的实践中，default VPC （内含有多个subnet和availab zone，创建EC2 instance 时候IP所在的zone不可控）不能满足要求。主要是跨 available zone 的流量还需要收费，一般的服务不需要跨 zone。所以需要自己创建VPC。

- 创建VPC时候的IP地址范围是可以选择的，选择一个喜欢的就好。
- 创建VPC的时候要选择IPv4， v6无所谓
- 创建VPC的时候一般来说选择一个public subnet就足够了（private subnet不必），public subnet是必须的，要不然不让自带堡垒机访问
- 创建VPC的之后，新增自己的Security Group 就好，删除的时候会一起删除
- 不用创建NAT gateway（收费），Internet Gateway 会自动创建（免费）

生产环境还是需要创建专属的VPC

