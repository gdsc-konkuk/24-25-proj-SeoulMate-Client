import UIKit
import SnapKit

final class CollectionCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        return v
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Gyeongbokgung"
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .white
        return label
    }()
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "161, Sajik-ro,\nJongno-gu, Seoul"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(70)
        }
        overlayView.addSubview(titleLabel)
        overlayView.addSubview(addressLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.left.right.equalTo(titleLabel)
        }
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configure(imageName: String) {
        imageView.image = UIImage(systemName: imageName)
        // 실제 데이터 적용 시 titleLabel.text, addressLabel.text도 세팅
    }
} 